require 'spec_helper'

describe Manifest do

  def manifest_from_json_mappings(mappings_json)
    Manifest.new(definition: "{\"metadata\":{\"source\" : {\"type\" : \"json\"}},\"field_mapping\" : #{mappings_json}}")
  end

  def assert_manifest_application(mappings_json, data, expected)
    manifest = manifest_from_json_mappings(mappings_json)
    result = manifest.apply_to(data)
    expected = {
      event:   { indexed: {}, custom: {}, pii: {} },
      sample:  { indexed: {}, custom: {}, pii: {} },
      patient: { indexed: {}, custom: {}, pii: {} },
    }.deep_merge(expected)

    result.should eq(expected.recursive_stringify_keys!)
  end

  def assert_raises_manifest_data_validation(mappings_json, data, message)
    manifest = manifest = manifest_from_json_mappings(mappings_json)
    expect { manifest.apply_to(data) }.to raise_error(message)
  end

  let (:definition) do
    %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "1.1.0",
        "version" : 1,
        "source" : {"type" : "json"}
      },
      "field_mapping" : {}
    }}
  end

  it "creates a device model named according to the manifest" do
    Manifest.create!(definition: definition)

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(definition)
    DeviceModel.count.should eq(1)
    Manifest.first.device_models.first.name.should eq("foo")
  end

  it "updates its version number" do
    updated_definition = %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "1.1.0",
        "version" : "2.0.1",
        "source" : {"type" : "json"}
      },
      "field_mapping" : {}
    }}

    Manifest.create!(definition: definition)

    manifest = Manifest.first

    manifest.version.should eq("1")
    manifest.definition = updated_definition
    manifest.save!

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.version.should eq("2.0.1")
  end

  it "updates its api_version number" do
    updated_definition = %{{
      "metadata" : {
        "device_models" : ["foo"],
        "api_version" : "1.1.1",
        "version" : 1,
        "source" : {"type" : "json"}
      },
      "field_mapping" : {}
    }}

    Manifest.create!(definition: definition)

    manifest = Manifest.first

    manifest.api_version.should eq('1.1.0')
    manifest.definition = updated_definition
    manifest.save!

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.api_version.should eq("1.1.1")
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
    Manifest.create!(definition: definition)

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.destroy()
    Manifest.count.should eq(0)

    Manifest.create!(definition: definition)

    definition_bar = %{{
      "metadata" : {
        "version" : 1,
        "api_version" : "1.1.0",
        "device_models" : ["bar"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {}
    }}

    Manifest.create!(definition: definition_bar)

    Manifest.count.should eq(2)
    DeviceModel.count.should eq(2)
    Manifest.first.destroy()
    Manifest.count.should eq(1)
    DeviceModel.count.should eq(2)

    definition_version = %{{
      "metadata" : {
        "version" : 2,
        "api_version" : "1.1.0",
        "device_models" : ["foo"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {}
    }}

    manifest = Manifest.first

    manifest.version.should eq("1")
    manifest.definition = definition_version
    manifest.save!

    DeviceModel.count.should eq(2)

    Manifest.first.device_models.first.should eq(DeviceModel.first)
    DeviceModel.first.name.should eq("foo")
  end

  it "should apply to indexed core fields" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "assay_name",
            "source" : {"lookup" : "assay.name"},
            "core" : true
          }]
        }
      },
      '{"assay" : {"name" : "GX4002"}}',
      event: {indexed: {"assay_name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
  end

  it "should apply to pii core field" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "patient_name",
            "source" : {"lookup" : "patient.name"},
            "core" : true,
            "pii" : true
          }]
        }
      },
      '{"patient" : {"name" : "John"}}',
      patient: {indexed: Hash.new, pii: {"patient_name" => "John"}, custom: Hash.new}
  end

  it "should apply to custom non-pii non-indexed field" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "temperature",
            "source" : {"lookup" : "temperature"},
            "core" : false,
            "pii" : false,
            "indexed" : false
          }]
        }
      },
      '{"temperature" : 20}',
      event: {indexed: Hash.new, pii: Hash.new, custom: {"temperature" => 20}}
  end

  it "should apply to custom non-pii indexed field" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "temperature",
            "source" : {"lookup" : "temperature"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{"temperature" : 20}',
      event: {indexed: {"custom_fields" => {"temperature" => 20}}, pii: Hash.new, custom: Hash.new}
  end

  it "should apply to custom non-pii indexed field inside results array" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "results[*].temperature",
            "source" : {"lookup" : "temperature"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{"temperature" : 20}',
      event: {indexed: {"results" => [{"custom_fields" => {"temperature" => 20}}]}, pii: Hash.new, custom: Hash.new}
  end

  it "should store fields in sample, event or patient as specified" do
    manifest = Manifest.new(definition: %{
      {
        "metadata": {
          "source" : {"type" : "json"}
        },
        "field_mapping" : {
          "sample" : [
            {
              "target_field" : "sample_id",
              "source" : {"lookup" : "sample_id"},
              "core" : true,
              "indexed" : true
            },
            {
              "target_field" : "sample_type",
              "source" : {"lookup" : "sample_type"},
              "core" : true,
              "indexed" : true
            },
            {
              "target_field" : "culture_days",
              "source" : {"lookup" : "culture_days"},
              "indexed" : true,
              "custom" : true
            },
            {
              "target_field" : "datagram",
              "source" : {"lookup" : "datagram"},
              "custom" : true
            },
            {
              "target_field" : "collected_at",
              "source" : {"lookup" : "collected_at"},
              "pii" : true
            }
          ],
          "patient" : [
            {
              "target_field" : "patient_id",
              "source" : {"lookup" : "patient_id"},
              "pii" : true
            },
            {
              "target_field" : "gender",
              "source" : {"lookup" : "gender"},
              "core" : true,
              "indexed" : true
            },
            {
              "target_field" : "dob",
              "source" : {"lookup" : "dob"},
              "core" : true,
              "pii" : true
            },
            {
              "target_field" : "hiv",
              "source" : {"lookup" : "hiv"},
              "custom" : true,
              "indexed" : true
            },
            {
              "target_field" : "shirt_color",
              "source" : {"lookup" : "shirt_color"},
              "custom" : true
            }
          ],
          "event" : [
            {
              "target_field" : "event_id",
              "source" : {"lookup" : "event_id"},
              "core" : true
            },
            {
              "target_field" : "assay",
              "source" : {"lookup" : "assay"},
              "core" : true,
              "indexed" : true
            },
            {
              "target_field" : "start_time",
              "source" : {"lookup" : "start_time"},
              "core" : true,
              "pii" : true
            },
            {
              "target_field" : "raw_result",
              "source" : {"lookup" : "raw_result"},
              "custom" : true
            },
            {
              "target_field" : "concentration",
              "source" : {"lookup" : "concentration"},
              "custom" : true,
              "indexed" :true
            }
          ]
        }
      }
    })

    result = manifest.apply_to(Oj.dump({
      event_id: "4",                    # event id
      assay: "mtb",                     # test, indexable
      start_time: "2000/1/1 10:00:00",  # test, pii
      concentration: "15%",             # test, indexable, custom
      raw_result: "positivo 15%",       # test, no indexable, custom
      sample_id: "4002",                # sample id
      sample_type: "sputum",            # sample, indexable
      collected_at: "2000/1/1 9:00:00", # sample, pii, non indexable
      culture_days: "10",               # sample, indexable, custom,
      datagram: "010100011100",         # sample, non indexable, custom
      patient_id: "8000",               # patient id
      gender: "male",                   # patient, indexable
      dob: "2000/1/1",                  # patient, pii, non indexable
      hiv: "positive",                  # patient, indexable, custom
      shirt_color: "blue"               # patient, non indexable, custom
    }))

    result.should eq({
      event: {
        indexed: {
          event_id: "4",
          assay: "mtb",
          custom_fields: {
            concentration: "15%"
          }
        },
        custom: {
          raw_result: "positivo 15%"
        },
        pii: {
          start_time: "2000/1/1 10:00:00"
        }
      },
      sample: {
        indexed: {
          sample_id: "4002",
          sample_type: "sputum",
          custom_fields: {
            culture_days: "10"
          }
        },
        custom: {
          datagram: "010100011100"
        },
        pii: {
          collected_at: "2000/1/1 9:00:00"
        }
      },
      patient: {
        indexed: {
          gender: "male",
          custom_fields: {
            hiv: "positive"
          }
        },
        pii: {
          patient_id: "8000",
          dob: "2000/1/1"
        },
        custom: {
          shirt_color: "blue"
        }
      }
    }.recursive_stringify_keys!)
  end

  it "should apply to an array of custom non-pii indexed field inside results array" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "results[*].instant_temperature[*].value",
            "source" : {"lookup" : "tests[*].temperatures[*].value"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          },
          {
            "target_field" : "results[*].instant_temperature[*].sample_time",
            "source" : {"lookup" : "tests[*].temperatures[*].time"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          },
          {
            "target_field" : "results[*].condition",
            "source" : {"lookup" : "tests[*].condition"},
            "core" : true,
            "pii" : false,
            "indexed" : true
          },
          {
            "target_field" : "results[*].result",
            "source" : {"lookup" : "tests[*].result"},
            "core" : true,
            "pii" : false,
            "indexed" : true
          },
          {
            "target_field" : "final_temperature",
            "source" : {"lookup" : "temperature"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "temperature" : 20,
        "tests" : [
          {
            "result" : "positive",
            "condition" : "mtb",
            "temperatures" : [
              { "time": "start", "value": 12},
              { "time" : "end", "value": 23}
            ]
          },
          {
           "result" : "negative",
            "condition" : "rif",
            "temperatures" : [
              {"time" : "start", "value": 22},
              {"time" : "end", "value": 30}
            ]
          }
        ]
      }',
      event: {indexed: {
        "results" => [
          { "condition" => "mtb",
            "result" => "positive",
            "custom_fields" => {"instant_temperature" => [
              {"sample_time" => "start", "value" => 12},
              {"sample_time" => "end", "value" => 23}
            ]}
          },
          { "condition" => "rif",
            "result" => "negative",
            "custom_fields" => {"instant_temperature" => [
              {"sample_time" => "start", "value" => 22},
              {"sample_time" => "end", "value" => 30}
            ]}
          }
        ],
        "custom_fields" => {"final_temperature" => 20}
      }, pii: Hash.new, custom: Hash.new}
  end

  it "should apply to custom pii field" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "temperature",
            "source" : {"lookup" : "temperature"},
            "core" : false,
            "pii" : true,
            "indexed" : false
          }]
        }
      },
      '{"temperature" : 20}',
      event: {indexed: Hash.new, pii: {"temperature" => 20}, custom: Hash.new}
  end

  it "doesn't raise on valid value in options" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "level",
            "source" : {"lookup" : "level"},
            "core" : true,
            "pii" : false,
            "indexed" : true,
            "options" : ["low", "medium", "high"]
          }]
        }
      },
      '{"level" : "high"}',
      event: {indexed: {"level" => "high"}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on invalid value in options" do
    assert_raises_manifest_data_validation %{
        {
          "event" : [{
            "target_field" : "level",
            "type" : "enum",
            "source" : {"lookup" : "level"},
            "core" : false,
            "pii" : false,
            "indexed" : true,
            "options" : ["low", "medium", "high"]
          }]
        }
      },
      '{"level" : "John Doe"}',
      "'John Doe' is not a valid value for 'level' (valid options are: low, medium, high)"
  end

  it "doesn't raise on valid value in range" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "temperature",
            "source" : {"lookup" : "temperature"},
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
        }
      },
      '{"temperature" : 30}',
      event: {indexed: {"custom_fields" => {"temperature" => 30}}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on invalid value in range (lesser)" do
    assert_raises_manifest_data_validation %{
        {
          "event" : [{
            "target_field" : "temperature",
            "source" : {"lookup" : "temperature"},
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
        }
      },
      '{"temperature" : 29.9}',
      "'29.9' is not a valid value for 'temperature' (valid values must be between 30 and 31)"
  end

  it "should raise on invalid value in range (greater)" do
    assert_raises_manifest_data_validation %{
        {
          "event" : [{
            "target_field" : "temperature",
            "source" : {"lookup" : "temperature"},
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
        }
      },
      '{"temperature" : 31.1}',
      "'31.1' is not a valid value for 'temperature' (valid values must be between 30 and 31)"
  end

  it "doesn't raise on valid value in date iso" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "sample_date",
            "source" : {"lookup" : "sample_date"},
            "core" : true,
            "pii" : false,
            "indexed" : true,
            "valid_values" : {
              "date" : "iso"
            }
          }]
        }
      },
      '{"sample_date" : "2014-05-14T15:22:11+0000"}',
      event: {indexed: {"sample_date" => "2014-05-14T15:22:11+0000"}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on invalid value in date iso" do
    assert_raises_manifest_data_validation %{
        {
          "event" : [{
            "target_field" : "sample_date",
            "source" : {"lookup" : "sample_date"},
            "core" : true,
            "pii" : false,
            "indexed" : true,
            "valid_values" : {
              "date" : "iso"
            }
          }]
        }
      },
      '{"sample_date" : "John Doe"}',
      "'John Doe' is not a valid value for 'sample_date' (valid value must be an iso date)"
  end

  it "applies first value mapping" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "condition",
            "source" : {
              "map" : [
                {"lookup" : "condition"},
                [
                  { "match" : "*MTB*", "output" : "MTB"},
                  { "match" : "*FLU*", "output" : "H1N1"},
                  { "match" : "*FLUA*", "output" : "A1N1"}
                ]
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{"condition" : "PATIENT HAS MTB CONDITION"}',
      event: {indexed: {"condition" => "MTB"}, pii: Hash.new, custom: Hash.new}
  end

  it "applies second value mapping" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "condition",
            "source" : {
              "map" : [
                {"lookup" : "condition"},
                [
                  { "match" : "*MTB*", "output" : "MTB"},
                  { "match" : "*FLU*", "output" : "H1N1"},
                  { "match" : "*FLUA*", "output" : "A1N1"}
                ]
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{"condition" : "PATIENT HAS FLU CONDITION"}',
      event: {indexed: {"condition" => "H1N1"}, pii: Hash.new, custom: Hash.new}
  end

  it "should raise on mapping not found" do
    assert_raises_manifest_data_validation %{
        {
          "event" : [{
            "target_field" : "condition",
            "source" : {
              "map" : [
                {"lookup" : "condition"},
                [
                  { "match" : "*MTB*", "output" : "MTB"},
                  { "match" : "*FLU*", "output" : "H1N1"},
                  { "match" : "*FLUA*", "output" : "A1N1"}
                ]
              ]
            },
            "core" : false,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{"condition" : "PATIENT IS OK"}',
      "'PATIENT IS OK' is not a valid value for 'condition' (valid value must be in one of these forms: *MTB*, *FLU*, *FLUA*)"
  end

  it "should apply to multiple indexed field" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "list[*].temperature",
            "source" : {"lookup" : "temperature_list[*].temperature"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{"temperature_list" : [{"temperature" : 20}, {"temperature" : 10}]}',
      event: {indexed: {"custom_fields" => {"list" => [{"temperature" => 20}, {"temperature" => 10}]}}, pii: Hash.new, custom: Hash.new}
  end

  it "should map to multiple indexed fields to the same list" do
    assert_manifest_application %{{
        "event" : [
          {
            "target_field" : "collection[*].temperature",
            "source" : {"lookup" : "some_list[*].temperature"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          },
          {
            "target_field" : "collection[*].foo",
            "source" : {"lookup" : "some_list[*].bar"},
            "core" : false,
            "pii" : false,
            "indexed" : true
          }
        ]}
      },
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
      event: {indexed: {"custom_fields" => {"collection" => [
        {
          "temperature" => 20,
          "foo" => 12
        },
        {
          "temperature" => 10,
          "foo" => 2
        }]}}, pii: Hash.new, custom: Hash.new}
  end

  it "should map to multiple indexed fields to the same list accross multiple collections" do
    assert_manifest_application %{{
        "event" : [
          {
            "target_field" : "collection[*].temperature",
            "source" : {"lookup" : "temperature_list[*].temperature"},
            "core" : true,
            "pii" : false,
            "indexed" : true
          },
          {
            "target_field" : "collection[*].foo",
            "source" : {"lookup" : "other_list[*].bar"},
            "core" : true,
            "pii" : false,
            "indexed" : true
          }
        ]
      }},
      '{
        "temperature_list" : [{"temperature" : 20}, {"temperature" : 10}],
        "other_list" : [{"bar" : 10}, {"bar" : 30}, {"bar" : 40}]
      }',
      event: {indexed: {"collection" => [
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
        "api_version" : "1.1.0",
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
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:field_mapping].first.should eq("must be a json object")

    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : []
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:field_mapping].first.should eq("must be a json object")
  end

  pending "shouldn't create if a core field is provided with an invalid value mapping" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : [
        {
          "target_field" : "test_type",
          "source" : {
            "map" : [
              {"lookup" : "Test.test_type"},
              [
                { "match" : "*QC*", "output" : "Invalid mapping"},
                { "match" : "*Specimen*", "output" : "specimen"}
              ]
            ]
          },
          "type" : "enum",
          "core" : true,
          "options" : [ "qc", "specimen" ]
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
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "test_type",
            "source" : {
              "map" : [
                {"lookup" : "Test.test_type"},
                [
                  { "match" : "*QC*", "output" : "qc"},
                  { "match" : "*Specimen*", "output" : "specimen"}
                ]
              ]
            },
            "core" : true,
            "type" : "enum",
            "options" : ["qc", "specimen"]
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(1)
  end

  it "shouldn't create if a core field is provided without source" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "results[*].result",
            "core" : true
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_field_mapping].first.should eq(": target 'results[*].result'. Mapping must include 'target_field' and 'source' fields")
  end

  it "shouldn't create if a custom field is provided without type" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "patient_name",
            "source" : {"lookup" : "patient_name"},
            "core" : false
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_type].first.should eq(": target 'patient_name'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
  end

  it "shouldn't create if a custom field is provided with an invalid type" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "patient_name",
            "source" : {"lookup" : "patient_name"},
            "type" : "quantity",
            "core" : false
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:invalid_type].first.should eq(": target 'patient_name'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
  end

  it "should create when fields are provided with valid types" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "patient_name",
            "source" : {"lookup" : "patient_name"},
            "type" : "string",
            "core" : false
          },
          {
            "target_field" : "control_date",
            "source" : {"lookup": "control_date"},
            "type" : "date",
            "core" : false
          },
          {
            "target_field" : "rbc_count",
            "source" : {"lookup": "rbc_count"},
            "type" : "integer",
            "core" : false
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(1)
  end

  it "shouldn't create if string 'null' appears as valid value of some field" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "rbc_description",
            "source" : {"lookup" : "rbc_description"},
            "type" : "enum",
            "core" : false,
            "options" : ["high","low","null"]
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:string_null].first.should eq(": cannot appear as a possible value. (In 'rbc_description') ")
  end

  it "shouldn't create if an enum field is provided without options" do
    definition = %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "json"}
      },
      "field_mapping" : {
        "event" : [
          {
            "target_field" : "results[*].result",
            "source" : {"lookup" : "result"},
            "core" : true,
            "type" : "enum"
          }
        ]
      }
    }}
    m = Manifest.new(definition: definition)
    m.save
    Manifest.count.should eq(0)
    m.errors[:enum_fields].first.should eq("must be provided with options. (In 'results[*].result'")
  end

  it "concats two or more elements" do
    assert_manifest_application %{
        {
        "patient" : [{
            "target_field" : "name",
            "source" : {
              "concat" : [
                {"lookup" : "last_name"},
                ", ",
                {"lookup" : "first_name"}
              ]
            },
            "core" : false,
            "pii" : true,
            "indexed" : false
          }]
        }
      },
      '{
        "first_name" : "John",
        "last_name" : "Doe"
      }',
      patient: {indexed: Hash.new, pii: {"name" => "Doe, John"}, custom: Hash.new}
  end

  it "strips spaces from an element" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "name",
            "source" : {
              "concat" : [
                {"strip" : {"lookup" : "last_name"}},
                ", ",
                {"lookup" : "first_name"}
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "first_name" : "John",
        "last_name" : "   Doe   "
      }',
      patient: {indexed: {"name" => "Doe, John"}, pii: Hash.new, custom: Hash.new}
  end


  it "concats the result of a mapping" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "foo",
            "source" : {
              "concat" : [
                {"strip" : {"lookup" : "last_name"}},
                ": ",
                {
                  "map" : [
                    {"lookup" : "test_type"},
                    [
                      { "match" : "*QC*", "output" : "qc"},
                      { "match" : "*Specimen*", "output" : "specimen"}
                    ]
                  ]
                }
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "test_type" : "This is a QC test",
        "last_name" : "   Doe   "
      }',
      event: {indexed: {"foo" => "Doe: qc"}, pii: Hash.new, custom: Hash.new}
  end

  it "maps the result of a concat" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "test_type",
            "source" : {
              "map" : [
                {
                  "concat" : [
                    {"strip" : {"lookup" : "last_name"}},
                    ": ",
                    {"strip" : {"lookup" : "first_name"}}
                  ]
                },
                [
                  { "match" : "Subject:*", "output" : "specimen"},
                  { "match" : "Doe: John", "output" : "qc"}
                ]
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "first_name" : " John ",
        "last_name" : "   Doe   "
      }',
      event: {indexed: {"test_type" => "qc"}, pii: Hash.new, custom: Hash.new}
  end

  it "retrieves a substring of an element" do
    assert_manifest_application %{
        {
          "event" : [
            {
              "target_field" : "test",
              "source" : {
                "substring" : [{"lookup" : "name_and_test"}, 0, 2]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            },
            {
              "target_field" : "first_name",
              "source" : {
                "substring" : [{"lookup" : "name_and_test"}, 4, -5]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }
          ]
        }
      },
      '{
        "name_and_test" : "ABC John Doe"
      }',
      event: {indexed: {"test" => "ABC", "first_name" => "John"}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the beginning of the month" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "month",
            "source" : {
              "beginning_of" : [
                {"lookup" : "run_at"},
                "month"
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000"
      }',
      event: {indexed: {"month" => "2014-05-01T00:00:00+0000"}, pii: Hash.new, custom: Hash.new}
  end

  it "parses an strange date" do
    assert_manifest_application %{
        {
          "event" : [{
            "target_field" : "month",
            "source" : {
              "parse_date" : [
                {"lookup" : "run_at"},
                "%a%d%b%y%H%p%z"
              ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "sat3feb014pm+7"
      }',
      event: {indexed: {"month" => "2001-02-03T16:00:00+0700"}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in years between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "years_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 1}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in months between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "months_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 13}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in days between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "days_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 396}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in hours between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "hours_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 9526}, pii: Hash.new, custom: Hash.new}
      # 396 days and 22 hours
  end

  it "obtains the distance in minutes between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "minutes_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 571618}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in seconds between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "seconds_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 34297139}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in milliseconds between two dates" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "milliseconds_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 34297139877000}, pii: Hash.new, custom: Hash.new}
  end

  it "obtains the distance in milliseconds between two dates disregarding the order" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "milliseconds_between" : [
                  {"lookup" : "run_at"},
                  {"lookup" : "birth_day"}
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "run_at" : "2014-05-14T15:22:11+0000",
        "birth_day" : "2013-04-12T16:23:11.123+0000"
      }',
      patient: {indexed: {"age" => 34297139877000}, pii: Hash.new, custom: Hash.new}
  end

  it "converts from minutes to hours" do
    assert_manifest_application %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "convert_time" : [
                  {"lookup" : "age"},
                  {"lookup" : "unit"},
                  "hours"
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      },
      '{
        "age" : "90",
        "unit" : "minutes"
      }',
      patient: {indexed: {"age" => 1.5}, pii: Hash.new, custom: Hash.new}
  end

  it "clusterises a number" do
    definition = %{
        {
          "patient" : [{
            "target_field" : "age",
            "source" : {
              "clusterise" : [
                  {"lookup" : "age"},
                  [5, 20, 40]
                ]
            },
            "core" : true,
            "pii" : false,
            "indexed" : true
          }]
        }
      }

    assert_manifest_application definition, '{ "age" : "30" }', patient: {indexed: {"age" => "20-40"}, pii: Hash.new, custom: Hash.new}

    assert_manifest_application definition, '{ "age" : "90" }', patient: {indexed: {"age" => "40+"}, pii: Hash.new, custom: Hash.new}

    assert_manifest_application definition, '{ "age" : "2" }', patient: {indexed: {"age" => "0-5"}, pii: Hash.new, custom: Hash.new}

    assert_manifest_application definition, '{ "age" : "20.1" }', patient: {indexed: {"age" => "20-40"}, pii: Hash.new, custom: Hash.new}

    assert_manifest_application definition, '{ "age" : "20" }', patient: {indexed: {"age" => "5-20"}, pii: Hash.new, custom: Hash.new}

    assert_manifest_application definition, '{ "age" : "40" }', patient: {indexed: {"age" => "20-40"}, pii: Hash.new, custom: Hash.new}
  end

  pending "Multiple fields" do
    it "should map single indexed field to a list" do
      assert_manifest_application %{{
          "event" : [
            {
              "target_field" : "collection[*].temperature",
              "source" : {"lookup" : "temperature"},
              "core" : true,
              "pii" : false,
              "indexed" : true
            }
          ]
        }},
        '{
          "temperature" : 20
        }',
        event: {indexed: {"collection" => [
          {
            "temperature" => 20
          }]}, pii: Hash.new, custom: Hash.new}
    end

    it "concats two or more elements" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].name",
              "source" : {
                "concat" : [
                  {"lookup" : "last_name"},
                  ", ",
                  {"lookup" : "conditions[*].name"},
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "last_name" : "Doe",
           "conditions" : [
            {
              "name" : "foo"
            },
            {
              "name": "bar"
            }
          ]
        }',
        patient: {indexed: {"results" => [{"name" => "Doe, foo"}, {"name" => "Doe, bar"}]}, pii: Hash.new, custom: Hash.new}
    end

    it "strips spaces from multiple elements" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].name",
              "source" : {
                {"strip" : {"lookup" : "conditions[*].name"}}
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "conditions" : [
            {
              "name" : "    foo    "
            },
            {
              "name": "    bar   "
            },
          ]
        }',
        patient: {indexed: {"results" => [{"name" => "foo"}, {"name" => "bar"}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should apply value mapping to multiple indexed field" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].condition",
              "source" : {
                "map" : [
                  {"lookup" : "conditions[*].condition"},
                  [
                    { "match" : "*MTB*", "output" : "MTB"},
                    { "match" : "*FLU*", "output" : "H1N1"},
                    { "match" : "*FLUA*", "output" : "A1N1"}
                  ]
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{"conditions" : [{"condition" : "PATIENT HAS MTB CONDITION"}, {"condition" : "PATIENT HAS FLU CONDITION"}]}',
        event: {indexed: {"results" => [{"condition" => "MTB"}, {"condition" => "H1N1"}]}, pii: Hash.new, custom: Hash.new}
    end

    it "retrieves a substring of an element" do
      assert_manifest_application %{
          {
            "event" : [
              {
                "target_field" : "test",
                "source" : {
                  "substring" : [{"lookup" : "name_and_test"}, 0, 2]
                },
                "core" : true,
                "pii" : false,
                "indexed" : true
              },
              {
                "target_field" : "first_name",
                "source" : {
                  "substring" : [{"lookup" : "name_and_test"}, 4, -5]
                },
                "core" : true,
                "pii" : false,
                "indexed" : true
              }
            ]
          }
        },
        '{
          "name_and_test" : "ABC John Doe"
        }',
        event: {indexed: {"test" => "ABC", "first_name" => "John"}, pii: Hash.new, custom: Hash.new}
    end

    it "obtains the beginning of the month" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "month",
              "source" : {
                "beginning_of" : [
                  {"lookup" : "run_at"},
                  "month"
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000"
        }',
        event: {indexed: {"month" => "2014-05-01T00:00:00+0000"}, pii: Hash.new, custom: Hash.new}
    end

    it "parses an strange date" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "month",
              "source" : {
                "parse_date" : [
                  {"lookup" : "run_at"},
                  "%a%d%b%y%H%p%z"
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "run_at" : "sat3feb014pm+7"
        }',
        event: {indexed: {"month" => "2001-02-03T16:00:00+0700"}, pii: Hash.new, custom: Hash.new}
    end

    it "should count years between multiple indexed fields" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].age",
              "source" : {
                "years_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        event: {indexed: {"results" => [{"age" => 1}, {"age" => 1}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count years between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "years_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 1}, {"age" => 1}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count years between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "years_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        event: {indexed: {"results" => [{"time" => 1}, {"time" => 1}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count months between multiple indexed fields" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "months_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 396}, {"age" => 397}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count months between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "months_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 396}, {"age" => 397}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count months between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "months_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        event: {indexed: {"results" => [{"time" => 396}, {"time" => 398}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count days between multiple indexed fields" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "days_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 396}, {"age" => 397}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count days between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "days_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 396}, {"age" => 397}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count days between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "days_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        event: {indexed: {"results" => [{"time" => 396}, {"time" => 398}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count hours between multiple indexed fields" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "hours_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 9526}, {"age" => 9526}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count hours between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "hours_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 9526}, {"age" => 9526}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count hours between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "hours_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        event: {indexed: {"results" => [{"time" => 9526}, {"time" => 9526}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count minutes between multiple indexed fields" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "minutes_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 571618}, {"age" => 571618}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count minutes between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "minutes_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 571618}, {"age" => 571618}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count minutes between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "minutes_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        event: {indexed: {"results" => [{"time" => 571618}, {"time" => 571618}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count seconds between multiple indexed fields" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "seconds_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 34297139}, {"age" => 34297139}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count seconds between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "seconds_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 34297139}, {"age" => 34297139}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count seconds between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "seconds_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        event: {indexed: {"results" => [{"time" => 34297139}, {"time" => 34297139}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count milliseconds between multiple indexed fields" do
      assert_manifest_application %{
          {
            "patient" : [{
              "target_field" : "results[*].age",
              "source" : {
                "milliseconds_between" : [
                  {"lookup" : "conditions[*].start_time"},
                  {"lookup" : "birth_day"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        patient: {indexed: {"results" => [{"age" => 34297139877000}, {"age" => 34297139877000}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count milliseconds between multiple indexed fields on the second parameter" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].age",
              "source" : {
                "milliseconds_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {"run_at" : "2014-05-14T15:22:11+0000"},
            {"run_at" : "2014-05-15T15:22:11+0000"}
          ]}',
        event: {indexed: {"results" => [{"age" => 34297139877000}, {"age" => 34297139877000}]}, pii: Hash.new, custom: Hash.new}
    end

    it "should count milliseconds between multiple indexed fields on both parameters" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].time",
              "source" : {
                "milliseconds_between" : [
                  {"lookup" : "conditions[*].end_time"},
                  {"lookup" : "conditions[*].run_at"}
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "birth_day" : "2013-04-12T16:23:11.123+0000",
          "conditions" : [
            {
              "run_at" : "2014-05-14T15:22:11+0000",
              "end_time" : "2013-04-12T16:23:11.123+0000"
            },
            {
              "run_at" : "2014-05-15T15:22:11+0000",
              "end_time" : "2013-04-13T16:23:11.123+0000"
            },
          ]}',
        {indexed: {"results" => [{"time" => 34297139877000}, {"time" => 34297139877000}]}, pii: Hash.new, custom: Hash.new}
    end

    it "converts from minutes to hours" do
      assert_manifest_application %{
          {
            "event" : [{
              "target_field" : "results[*].age",
              "source" : {
                "convert_time" : [
                    {"lookup" : "multiple[*].age"},
                    {"lookup" : "unit"},
                    "hours"
                  ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "multiple" : [
            {"age" : "90"},
            {"age" : "60"}
          ],
          "unit" : "minutes"
        }',
        {indexed: {"results" => [{"age" => 1.5}, {"age" => 1}]}, pii: Hash.new, custom: Hash.new}
    end

    it "clusterises an array of numbers" do
      definition = %{
          {
            "event" : [{
              "target_field" : "results[*].age",
              "source" : {
                "clusterise" : [
                    {"lookup" : "multiple[*].age"},
                    [5, 20, 40]
                  ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        }

      assert_manifest_application definition,
        '{
          "multiple" : [
            {"age" : "30"},
            {"age" : "90"},
            {"age" : "2"},
            {"age" : "20.1"},
            {"age" : "20"},
            {"age" : "40"}
          ],
        }',
        {indexed: {"results" => [
          {"age" => "20-40"},
          {"age" => "40+"},
          {"age" => "0-5"},
          {"age" => "20-40"},
          {"age" => "5-20"},
          {"age" => "20-40"}
        ]}, pii: Hash.new, custom: Hash.new}
    end
  end
end
