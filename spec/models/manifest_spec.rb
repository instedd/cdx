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

  it "creates a device model named according to the manifest" do
    manifest = '{"metadata" : {"device_models" : ["foo"]}}'
    Manifest.create(definition: manifest)

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(manifest)
    DeviceModel.count.should eq(1)
    Manifest.first.device_models.first.name.should eq("foo")
  end

  it "updates it's version number" do
    Manifest.create(definition: '{"metadata" : {"device_models" : ["foo"], "version" : 1}}')

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = '{"metadata" : {"device_models" : ["foo"], "version" : 2}}'
    manifest.save!

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.version.should eq(2)
  end

  it "leaves no orphan model" do
    Manifest.create(definition: '{"metadata" : {"device_models" : ["foo"], "version" : 1}}')

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.destroy()
    Manifest.count.should eq(0)
    DeviceModel.count.should eq(0)

    Manifest.create(definition: '{"metadata" : {"device_models" : ["foo"], "version" : 1}}')
    Manifest.create(definition: '{"metadata" : {"device_models" : ["bar"], "version" : 1}}')

    Manifest.count.should eq(2)
    DeviceModel.count.should eq(2)
    Manifest.first.destroy()
    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)

    Manifest.first.device_models.first.should eq(DeviceModel.first)

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = '{"metadata" : {"device_models" : "foo", "version" : 2}}'
    manifest.save!
    DeviceModel.count.should eq(1)

    Manifest.first.device_models.first.should eq(DeviceModel.first)
    DeviceModel.first.name.should eq("foo")
  end

  it "should apply to indexed core fields" do
    assert_manifest_application %{
        [{
          "target_field" : "assay_name",
          "selector" : "assay.name",
          "type" : "core"
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
          "type" : "core"
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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

  it "should raises on invalid value in options" do
    assert_raises_manifest_data_validation %{
        [{
          "target_field" : "level",
          "selector" : "level",
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
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
          "type" : "custom",
          "pii" : false,
          "indexed" : true
        }]
      },
      '{"temperature_list" : [{"temperature" : 20}, {"temperature" : 10}]}',
      {indexed: {"list" => [{"temperature" => 20}, {"temperature" => 10}]}, pii: Hash.new, custom: Hash.new}
  end

  it "should map to multiple indexed fields to the same list" do
    assert_manifest_application %{[
        {
          "target_field" : "collection[*].temperature",
          "selector" : "some_list[*].temperature",
          "type" : "custom",
          "pii" : false,
          "indexed" : true
        },
        {
          "target_field" : "collection[*].foo",
          "selector" : "some_list[*].bar",
          "type" : "custom",
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
          "type" : "custom",
          "pii" : false,
          "indexed" : true
        },
        {
          "target_field" : "collection[*].foo",
          "selector" : "other_list[*].bar",
          "type" : "custom",
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
end
