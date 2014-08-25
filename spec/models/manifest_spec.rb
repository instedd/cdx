require 'spec_helper'

describe Manifest do

  def assert_manifest_application(mappings_json, data, expected)
    manifest = Manifest.new(definition: "{\"field_mapping\" : #{mappings_json}}")
    result = manifest.apply_to(Oj.load(data))
    result.should eq(expected)
  end

  def assert_raises_manifest_data_validation(mappings_json, data, message)
    manifest = Manifest.new(definition: "{\"field_mapping\" : #{mappings_json}}")
    expect { manifest.apply_to(Oj.load(data)) }.to raise_error
  end

  let (:definition) do
    %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "1.0.0",
        "version" : 1
      },
      "field_mapping" : []
    }}
  end

  it "creates a device model named according to the manifest" do
    Manifest.create(definition: definition)

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(definition)
    DeviceModel.count.should eq(1)
    Manifest.first.device_models.first.name.should eq("foo")
  end

  it "updates it's version number" do
    updated_definition = %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "1.0.0",
        "version" : 2
      },
      "field_mapping" : []
    }}

    Manifest.create(definition: definition)

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = updated_definition
    manifest.save!

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.version.should eq(2)
  end

  it "updates it's api_version number" do
    updated_definition = %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "2.0.0",
        "version" : 1
      },
      "field_mapping" : []
    }}

    Manifest.create(definition: definition)

    manifest = Manifest.first

    manifest.api_version.should eq('1.0.0')
    manifest.definition = updated_definition
    manifest.save!

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.api_version.should eq("2.0.0")
  end

  it "reuses an existing device model if it already exists" do
    Manifest.create definition: definition
    Manifest.first.destroy

    model = DeviceModel.first

    Manifest.create definition: definition

    DeviceModel.count.should eq(1)
    DeviceModel.first.id.should eq(model.id)
  end

  it "leaves device models after being deleted" do
    Manifest.create definition: definition

    Manifest.first.destroy

    Manifest.count.should eq(0)
    DeviceModel.count.should eq(1)
  end

  it "leaves no orphan model" do
    Manifest.create(definition: definition)

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.destroy()
    Manifest.count.should eq(0)

    Manifest.create(definition: definition)

    definition_bar = %{{
      "metadata" : {
        "version" : 1,
        "api_version" : "1.0.0",
        "device_models" : ["bar"]
      },
      "field_mapping" : []
    }}

    Manifest.create(definition: definition_bar)

    Manifest.count.should eq(2)
    DeviceModel.count.should eq(2)
    Manifest.first.destroy()
    Manifest.count.should eq(1)
    DeviceModel.count.should eq(2)

    definition_version = %{{
      "metadata" : {
        "version" : 2,
        "api_version" : "1.0.0",
        "device_models" : ["foo"]
      },
      "field_mapping" : []
    }}

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = definition_version
    manifest.save!

    DeviceModel.count.should eq(2)

    Manifest.first.device_models.first.should eq(DeviceModel.first)
    DeviceModel.first.name.should eq("foo")
  end

  it "should apply to indexed core fields" do
    assert_manifest_application %{
        [{
          "target_field" : "assay_name",
          "selector" : "assay.name",
          "core" : true
        }]
      },
      '{"assay" : {"name" : "GX4002"}}',
      {indexed: {"assay_name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
  end

  it "should apply to pii core field" do
    assert_manifest_application %{
        [{
          "target_field" : "patient_name",
          "selector" : "patient.name",
          "core" : true
        }]
      },
      '{"patient" : {"name" : "John"}}',
      {indexed: Hash.new, pii: {"patient_name" => "John"}, custom: Hash.new}
  end

  it "should apply to custom non-pii non-indexed field" do
    assert_manifest_application %{
        [{
          "target_field" : "temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : false,
          "indexed" : false
        }]
      },
      '{"temperature" : 20}',
      {indexed: Hash.new, pii: Hash.new, custom: {"temperature" => 20}}
  end

  it "should apply to custom non-pii indexed field" do
    assert_manifest_application %{
        [{
          "target_field" : "temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true
        }]
      },
      '{"temperature" : 20}',
      {indexed: {"temperature" => 20}, pii: Hash.new, custom: Hash.new}
  end

  it "should apply to custom pii field" do
    assert_manifest_application %{
        [{
          "target_field" : "temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : true,
          "indexed" : false
        }]
      },
      '{"temperature" : 20}',
      {indexed: Hash.new, pii: {"temperature" => 20}, custom: Hash.new}
  end

  it "doesn't raise on valid value in options" do
    assert_manifest_application %{
        [{
          "target_field" : "level",
          "selector" : "level",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "options" : ["low", "medium", "high"]
          }
        }]
      },
      '{"level" : "high"}',
      {indexed: {"level" => "high"}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on invalid value in options" do
    assert_raises_manifest_data_validation %{
        [{
          "target_field" : "level",
          "selector" : "level",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "options" : ["low", "medium", "high"]
          }
        }]
      },
      '{"level" : "John Doe"}',
      "'John Doe' is not a valid value for 'level' (valid options are: low, medium, high)"
  end

  it "doesn't raise on valid value in range" do
    assert_manifest_application %{
        [{
          "target_field" : "temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "range" : {
              "min" : 30,
              "max" : 30
            }
          }
        }]
      },
      '{"temperature" : 30}',
      {indexed: {"temperature" => 30}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on invalid value in range (lesser)" do
    assert_raises_manifest_data_validation %{
        [{
          "target_field" : "temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "range" : {
              "min" : 30,
              "max" : 31
            }
          }
        }]
      },
      '{"temperature" : 29.9}',
      "'29.9' is not a valid value for 'temperature' (valid values must be between 30 and 31)"
  end

  it "should raise on invalid value in range (greater)" do
    assert_raises_manifest_data_validation %{
        [{
          "target_field" : "temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "range" : {
              "min" : 30,
              "max" : 31
            }
          }
        }]
      },
      '{"temperature" : 31.1}',
      "'31.1' is not a valid value for 'temperature' (valid values must be between 30 and 31)"
  end

  it "doesn't raise on valid value in date iso" do
    assert_manifest_application %{
        [{
          "target_field" : "sample_date",
          "selector" : "sample_date",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "date" : "iso"
          }
        }]
      },
      '{"sample_date" : "2014-05-14T15:22:11+0000"}',
      {indexed: {"sample_date" => "2014-05-14T15:22:11+0000"}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on invalid value in date iso" do
    assert_raises_manifest_data_validation %{
        [{
          "target_field" : "sample_date",
          "selector" : "sample_date",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "date" : "iso"
          }
        }]
      },
      '{"sample_date" : "John Doe"}',
      "'John Doe' is not a valid value for 'sample_date' (valid value must be an iso date)"
  end

  it "applies first value mapping" do
    assert_manifest_application %{
        [{
          "target_field" : "condition",
          "selector" : "condition",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "value_mappings" : {
            "*MTB*" : "MTB",
            "*FLU*" : "H1N1",
            "*FLUA*" : "A1N1"
          }
        }]
      },
      '{"condition" : "PATIENT HAS MTB CONDITION"}',
      {indexed: {"condition" => "MTB"}, pii: Hash.new, custom: Hash.new}
  end

  it "applies second value mapping" do
    assert_manifest_application %{
        [{
          "target_field" : "condition",
          "selector" : "condition",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "value_mappings" : {
            "*MTB*" : "MTB",
            "*FLU*" : "H1N1",
            "*FLUA*" : "A1N1"
          }
        }]
      },
      '{"condition" : "PATIENT HAS FLU CONDITION"}',
      {indexed: {"condition" => "H1N1"}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on mapping not found" do
    assert_raises_manifest_data_validation %{
        [{
          "target_field" : "condition",
          "selector" : "condition",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "value_mappings" : {
            "*MTB*" : "MTB",
            "*FLU*" : "H1N1",
            "*FLUA*" : "A1N1"
          }
        }]
      },
      '{"condition" : "PATIENT IS OK"}',
      "'PATIENT IS OK' is not a valid value for 'condition' (valid value must be in one of these forms: *FLU*, *FLUA*, *MTB*)"
  end

  it "should apply to multiple indexed field" do
    assert_manifest_application %{
        [{
          "target_field" : "list[*].temperature",
          "selector" : "temperature_list[*].temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true
        }]
      },
      '{"temperature_list" : [{"temperature" : 20}, {"temperature" : 10}]}',
      {indexed: {"list" => [{"temperature" => 20}, {"temperature" => 10}]}, pii: Hash.new, custom: Hash.new}
  end

  pending "should apply value mapping to multiple indexed field" do
    assert_manifest_application %{
        [{
          "target_field" : "results[*].condition",
          "selector" : "conditions[*].condition",
          "core" : false,
          "pii" : false,
          "indexed" : true,
          "value_mappings" : {
            "*MTB*" : "MTB",
            "*FLU*" : "H1N1",
            "*FLUA*" : "A1N1"
          }
        }]
      },
      '{"conditions" : [{"condition" : "PATIENT HAS MTB CONDITION"}, {"condition" : "PATIENT HAS FLU CONDITION"}]}',
      {indexed: {"results" => [{"condition" => "MTB"}, {"condition" => "H1N1"}]}, pii: Hash.new, custom: Hash.new}
  end

  it "should map to multiple indexed fields to the same list" do
    assert_manifest_application %{[
        {
          "target_field" : "collection[*].temperature",
          "selector" : "some_list[*].temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true
        },
        {
          "target_field" : "collection[*].foo",
          "selector" : "some_list[*].bar",
          "core" : false,
          "pii" : false,
          "indexed" : true
        }
      ]},
      '{
        "some_list" : [
          {
            "temperature" : 20,
            "bar" : 12
          },
          {
            "temperature" : 10,
            "bar" : 2
          }
        ]
      }',
      {indexed: {"collection" => [
        {
          "temperature" => 20,
          "foo" => 12
        },
        {
          "temperature" => 10,
          "foo" => 2
        }]}, pii: Hash.new, custom: Hash.new}
  end

  it "should map to multiple indexed fields to the same list accross multiple collections" do
    assert_manifest_application %{[
        {
          "target_field" : "collection[*].temperature",
          "selector" : "temperature_list[*].temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true
        },
        {
          "target_field" : "collection[*].foo",
          "selector" : "other_list[*].bar",
          "core" : false,
          "pii" : false,
          "indexed" : true
        }
      ]},
      '{
        "temperature_list" : [{"temperature" : 20}, {"temperature" : 10}],
        "other_list" : [{"bar" : 10}, {"bar" : 30}, {"bar" : 40}]
      }',
      {indexed: {"collection" => [
        {
          "temperature" => 20,
          "foo" => 10
        },
        {
          "temperature" => 10,
          "foo" => 30
        },
        {
          "foo" => 40
        }]}, pii: Hash.new, custom: Hash.new}
  end

  pending "should map single indexed field to a list" do
    assert_manifest_application %{[
        {
          "target_field" : "collection[*].temperature",
          "selector" : "temperature",
          "core" : false,
          "pii" : false,
          "indexed" : true
        }
      ]},
      '{
        "temperature" : 20
      }',
      {indexed: {"collection" => [
        {
          "temperature" => 20
        }]}, pii: Hash.new, custom: Hash.new}
  end

  it "shouldn't pass validations when creating if definition is an invalid json" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0" , ,
        "api_version" : "1.0.0"
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:parse_error].should_not eq(nil)
  end

  it "shouldn't pass validations if metadata is empty" do
    definition = %{{
      "metadata" : {
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:metadata].first.should eq("can't be blank")
  end

  it "shouldn't pass validations if metadata doesn't include version" do
    definition = %{{
      "metadata" : {
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : []
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:metadata].first.should eq("must include version field")
  end

  it "shouldn't pass validations if metadata doesn't include api_version" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : []
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:metadata].first.should eq("must include api_version field")
  end

  it "shouldn't pass validations if metadata doesn't include device_models" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0"
      },
      "field_mapping" : []
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:metadata].first.should eq("must include device_models field")
  end

  it "shouldn't pass validations if field_mapping is not an array" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:field_mapping].first.should eq("must be an array")

    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : {}
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:field_mapping].first.should eq("must be an array")
  end

  it "shouldn't create if a core field is provided with valid values" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "age",
          "selector" : "age",
          "core" : true,
          "valid_values" : {
            "range" : {
              "min" : 0,
              "max" : 100
            }
          }
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_field_mapping].first.should eq(": target 'age'. Valid values are not permitted for core fields")
  end

  it "shouldn't create if a core field is provided with an invalid value mapping" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "test_type",
          "selector" : "Test.test_type",
          "core" : true,
          "value_mappings" : {
            "*QC*" : "Invalid mapping",
            "*Specimen*" : "specimen"
          }
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_field_mapping].first.should eq(": target 'test_type'. 'Invalid mapping' is not a valid value")
  end

  it "should create if core fields are provided with valid value mappings" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "test_type",
          "selector" : "Test.test_type",
          "core" : true,
          "value_mappings" : {
            "*QC*" : "qc",
            "*Specimen*" : "specimen"
          }
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(1)
  end

  it "shouldn't create if a core field is provided without selector" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "results[*].result",
          "core" : true
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_field_mapping].first.should eq(": target 'results[*].result'. Mapping in core fields must include target_field and selector")
  end


  it "shouldn't create if a core field is provided without target_field" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "selector" : "result",
          "core" : true
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_field_mapping].first.should eq(": target 'result'. Mapping in core fields must include target_field and selector")
  end

  it "shouldn't create if a custom field is provided without type" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "patient_name",
          "selector" : "patient_name",
          "core" : false
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_type].first.should eq(": custom fields must include a type, with value 'integer', 'date' or 'string'")
  end

  it "shouldn't create if a custom field is provided with an invalid type" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "patient_name",
          "selector" : "patient_name",
          "type" : "quantity",
          "core" : false
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_type].first.should eq(": custom fields must include a type, with value 'integer', 'date' or 'string'")
  end

  it "should create when fields are provided with valid types" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.0.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : [
        {
          "target_field" : "patient_name",
          "selector" : "patient_name",
          "type" : "string",
          "core" : false
        },
        {
          "target_field" : "control_date",
          "selector" : "control_date",
          "type" : "date",
          "core" : false
        },
        {
          "target_field" : "rbc_count",
          "selector" : "rbc_count",
          "type" : "integer",
          "core" : false
        }
      ]
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(1)
  end

end
