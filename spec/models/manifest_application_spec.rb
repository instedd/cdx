require 'spec_helper'

describe Manifest, validate_manifest: false do

  context "applying to message" do

    it "should apply to indexed core fields" do
      assert_manifest_application %{
          {
            "test.assay_name" : {"lookup" : "assay.name"}
          }
        }, %{
          {"test.assay_name": {}}
        },
        '{"assay" : {"name" : "GX4002"}}',
        "test" => {"custom" => {"assay_name" => "GX4002"}, "pii" => {}, "indexed" => {}}
    end

    it "should fail to apply with a nested field" do
      mappings_json = '{ "test.assay_name" : {"lookup" : "assay.name"} }'
      custom_json = '[{"name": "test.assay_name"}]'

      manifest = manifest_from_json_mappings(mappings_json, custom_json, 'csv')

      expect {
        manifest.apply_to("assay.name\nGX4002", nil)
      }.to raise_error
    end

    it "should apply to pii core field" do
      assert_manifest_application %{
          {
            "patient.name" : {"lookup" : "patient.name"}
          }
        }, %{
          {"patient.name": {"pii": true}}
        },
        '{"patient" : {"name" : "John"}}',
        "patient" => {"indexed" => {}, "pii" => {"name" => "John"}, "custom" => {}}
    end

    it "should apply to custom non-pii field" do
      assert_manifest_application %{
          {
            "test.temperature" : {"lookup" : "temperature"}
          }
        }, %{
          {"test.temperature": {}}
        },
        {json: '{"temperature" : "20"}', csv: "temperature\n20"},
        "test" => {"indexed" => {}, "pii" => {}, "custom" => {"temperature" => "20"}}
    end

    it "should apply to custom non-pii field inside results array" do
      assert_manifest_application %{
          {
            "test.assays[*].temperature" : {"lookup" : "temperature"}
          }
        }, %{
          {
            "test.assays[*].temperature": {}
          }
        },
        '{"temperature" : "20"}',
        "test" => {"indexed" => {}, "pii" => {}, "custom" => {"assays"=>[{"temperature"=>"20"}]}}
    end

    it "should store fields in sample, test or patient as specified" do
      test = Oj.dump({
        test_id: "4",                     # test id
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
      })

      csv = "test_id;assay;start_time;concentration;raw_result;sample_id;sample_type;collected_at;culture_days;datagram;patient_id;gender;dob;hiv;shirt_color" +
      "\n4;mtb;2000/1/1 10:00:00;15%;positivo 15%;4002;sputum;2000/1/1 9:00:00;10;010100011100;8000;male;2000/1/1;positive;blue"

      custom_definition = %{
        {
          "sample.culture_days": { },
          "sample.datagram": { },
          "sample.collected_at": { "pii": true},
          "patient.dob": { "pii": true},
          "patient.shirt_color": {},
          "patient.hiv": {},
          "test.raw_result": {},
          "test.concentration": {}
        }
      }

      field_definition = %{{
        "sample.id": {"lookup" : "sample_id"},
        "sample.type": {"lookup" : "sample_type"},
        "sample.culture_days": {"lookup" : "culture_days"},
        "sample.datagram": {"lookup" : "datagram"},
        "sample.collected_at": {"lookup" : "collected_at"},
        "patient.id": {"lookup" : "patient_id"},
        "patient.gender": {"lookup" : "gender"},
        "patient.dob": {"lookup" : "dob"},
        "patient.hiv": {"lookup" : "hiv"},
        "patient.shirt_color": {"lookup" : "shirt_color"},
        "test.uuid": {"lookup" : "test_id"},
        "test.name": {"lookup" : "assay"},
        "test.start_time": {"lookup" : "start_time"},
        "test.raw_result": {"lookup" : "raw_result"},
        "test.concentration": {"lookup" : "concentration"}
      }}

      expected = {
        "test" => {
          "indexed" => {
            "uuid" => "4",
            "name" => "mtb",
            "start_time" => "2000/1/1 10:00:00"
          },
          "custom" => {
            "concentration" => "15%",
            "raw_result" => "positivo 15%"
          },
          "pii" => {}
        },
        "sample" => {
          "indexed" => {
            "id" => "4002",
            "type" => "sputum"
          },
          "custom" => {
            "datagram" => "010100011100",
            "culture_days" => "10"
          },
          "pii" => {
            "collected_at" => "2000/1/1 9:00:00"
          }
        },
        "patient" => {
          "indexed" => {
            "gender" => "male"
          },
          "pii" => {
            "id" => "8000",
            "dob" => "2000/1/1"
          },
          "custom" => {
            "hiv" => "positive",
            "shirt_color" => "blue"
          }
        }
      }

      assert_manifest_application field_definition, custom_definition, {json: test, csv: csv}, expected
    end

    it "should apply to an array of custom field inside assays array" do
      assert_manifest_application %{
          {
            "test.assays[*].instant_temperature[*].value": {
              "lookup" : "tests[*].temperatures[*].value"
            },
            "test.assays[*].instant_temperature[*].sample_time": {
              "lookup" : "tests[*].temperatures[*].time"
            },
            "test.assays[*].name": {
              "lookup" : "tests[*].condition"
            },
            "test.assays[*].qualitative_result": {
              "lookup" : "tests[*].result"
            },
            "test.final_temperature": {
              "lookup" : "temperature"
            }
          }
        }, %{
          {
            "test.assays[*].instant_temperature[*].value": {},
            "test.assays[*].instant_temperature[*].sample_time": {},
            "test.final_temperature": {}
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
        "test" => {
          "indexed" => { "assays" => [
            { "name" => "mtb", "qualitative_result" => "positive" },
            { "name" => "rif", "qualitative_result" => "negative" }
          ]},
          "pii" => {},
          "custom" => {
            "final_temperature" => 20,
            "assays" => [
              {
                "instant_temperature" => [
                  {"sample_time" => "start", "value" => 12},
                  {"sample_time" => "end", "value" => 23}
                ]
              },
              {
                "instant_temperature" => [
                  {"sample_time" => "start", "value" => 22},
                  {"sample_time" => "end", "value" => 30}
                ]
              }
            ]
          }
        }
    end

    it "should apply to custom pii field" do
      assert_manifest_application %{
          {
            "test.temperature": {"lookup" : "temperature"}
          }
        }, %{
          {
            "test.temperature": {"pii": true}
          }
        },
        '{"temperature" : 20}',
        "test" => {"indexed" => {}, "pii" => {"temperature" => 20}, "custom" => {}}
    end

    it "doesn't raise on valid value in range" do
      assert_manifest_application %{
          {
            "test.temperature" : {"lookup" : "temperature"}
          }
        }, %{
          {
            "test.temperature": {
              "valid_values": {
                "range" : {
                  "min" : 30,
                  "max" : 30
                }
              }
            }
          }
        },
        '{"temperature" : 30}',
        "test" => {"indexed" => {}, "pii" => {}, "custom" => {"temperature" => 30}}
    end

    it "should raise on invalid value in range (lesser)" do
      assert_raises_manifest_data_validation %{
          {
            "test.temperature" : {"lookup" : "temperature"}
          }
        }, %{
          {
            "test.temperature": {
              "valid_values": {
                "range" : {
                  "min" : 30,
                  "max" : 31
                }
              }
            }
          }
        },
        '{"temperature" : 29.9}',
        "'29.9' is not a valid value for 'test.temperature' (valid values must be between 30 and 31)"
    end

    it "should raise on invalid value in range (greater)" do
      assert_raises_manifest_data_validation %{
          {
            "test.temperature" : {"lookup" : "temperature"}
          }
        }, %{
          {
            "test.temperature": {
              "valid_values": {
                "range" : {
                  "min" : 30,
                  "max" : 31
                }
              }
            }
          }
        },
        '{"temperature" : 31.1}',
        "'31.1' is not a valid value for 'test.temperature' (valid values must be between 30 and 31)"
    end

    it "doesn't raise on valid value in date iso" do
      assert_manifest_application %{
          {
            "test.sample_date" : {"lookup" : "sample_date"}
          }
        }, %{
          {
            "test.sample_date": {
              "valid_values" : {
                "date" : "iso"
              }
            }
          }
        },
        '{"sample_date" : "2014-05-14T15:22:11+0000"}',
        "test" => {"custom" => {"sample_date" => "2014-05-14T15:22:11+0000"}, "pii" => {}, "indexed" => {}}
    end

    it "should raise on invalid value in date iso" do
      assert_raises_manifest_data_validation %{
          {
            "test.sample_date" : {"lookup" : "sample_date"}
          }
        }, %{
          {
            "test.sample_date": {
              "valid_values" : {
                "date" : "iso"
              }
            }
          }
        },
        '{"sample_date" : "John Doe"}',
        "'John Doe' is not a valid value for 'test.sample_date' (valid value must be an iso date)"
    end

    it "applies first value mapping" do
      assert_manifest_application %{
          {
            "test.condition": {
              "case" : [
                {"lookup" : "condition"},
                [
                  { "when" : "*MTB*", "then" : "MTB"},
                  { "when" : "*FLU*", "then" : "H1N1"},
                  { "when" : "*FLUA*", "then" : "A1N1"}
                ]
              ]
            }
          }
        }, %{
          {
            "test.condition": {}
          }
        },
        '{"condition" : "PATIENT HAS MTB CONDITION"}',
        "test" => {"custom" => {"condition" =>"MTB"}, "pii" => {}, "indexed" => {}}
    end

    it "applies second value mapping" do
      assert_manifest_application %{
          {
            "test.condition": {
              "case" : [
                {"lookup" : "condition"},
                [
                  { "when" : "*MTB*", "then" : "MTB"},
                  { "when" : "*FLU*", "then" : "H1N1"},
                  { "when" : "*FLUA*", "then" : "A1N1"}
                ]
              ]
            }
          }
        }, %{
          {
            "test.condition": {}
          }
        },
        '{"condition" : "PATIENT HAS FLU CONDITION"}',
        "test" => {"custom" => {"condition" => "H1N1"}, "pii" => {}, "indexed" => {}}
    end

    it "should raise on mapping not found" do
      assert_raises_manifest_data_validation %{
          {
            "test.condition": {
              "case" : [
                {"lookup" : "condition"},
                [
                  { "when" : "*MTB*", "then" : "MTB"},
                  { "when" : "*FLU*", "then" : "H1N1"},
                  { "when" : "*FLUA*", "then" : "A1N1"}
                ]
              ]
            }
          }
        }, %{
          {
            "test.condition": {}
          }
        },
        '{"condition" : "PATIENT IS OK"}',
        "'PATIENT IS OK' is not a valid value for 'test.condition' (valid value must be in one of these forms: *MTB*, *FLU*, *FLUA*)"
    end

    it "should apply to multiple indexed field" do
      assert_manifest_application %{
          {
            "test.list[*].temperature" : {
              "lookup" : "temperature_list[*].temperature"
            }
          }
        }, %{
          {
            "test.list[*].temperature": {}
          }
        },
        '{"temperature_list" : [{"temperature" : 20}, {"temperature" : 10}]}',
        "test" => {"indexed" => {}, "pii" => {}, "custom" => {"list" => [{"temperature" => 20}, {"temperature" => 10}]}}
    end

    it "should map to multiple indexed fields to the same list" do
      assert_manifest_application %{{
          "test.collection[*].temperature": {
            "lookup" : "some_list[*].temperature"
          },
          "test.collection[*].foo": {
            "lookup" : "some_list[*].bar"
          }
        }}, %{
          {
            "test.collection[*].temperature": {},
            "test.collection[*].foo": {}
          }
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
        "test" => {"indexed" => {}, "pii" => {}, "custom" => {"collection" => [
          {
            "temperature" => 20,
            "foo" => 12
          },
          {
            "temperature" => 10,
            "foo" => 2
          }]}}
    end

    it "should map to multiple indexed fields to the same list accross multiple collections" do
      assert_manifest_application %{{
          "test.collection[*].temperature": {
            "lookup" : "temperature_list[*].temperature"
          },
          "test.collection[*].foo": {
            "lookup" : "other_list[*].bar"
          }
        }}, %{
          {
            "test.collection[*].temperature": {},
            "test.collection[*].foo": {}
          }
        },
        '{
          "temperature_list" : [{"temperature" : 20}, {"temperature" : 10}],
          "other_list" : [{"bar" : 10}, {"bar" : 30}, {"bar" : 40}]
        }',
        "test" => {"custom" => {"collection" => [
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
          }]}, "pii" => {}, "indexed" => {}}
    end

    it "map custom fields to core fields" do
      device = Device.make custom_mappings: {"test.custom_id" => "patient.id"}
      assert_manifest_application '{
          "test.custom_id" :{ "lookup" : "custom_id" }
        }',
        '{"test.custom_id": {}}',
        {json: '{"custom_id" : "20"}', csv: "custom_id\n20"},
        {"patient" => {"pii" => {"id" => "20"}}},
        device
    end
  end
end
