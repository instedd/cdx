require 'spec_helper'

describe Manifest, validate_manifest: false do

  context "applying to message" do

    it "should apply to indexed core fields" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "assay_name",
              "source" : {"lookup" : "assay.name"},
              "core" : true
            }]
          }
        },
        '{"assay" : {"name" : "GX4002"}}',
        test: {indexed: {"assay_name" => "GX4002"}, pii: Hash.new, custom: Hash.new}
    end

    it "should fail to apply with a nested field" do
      mappings_json = %{{
                        "test" : [{
                          "target_field" : "assay_name",
                          "source" : {"lookup" : "assay.name"},
                          "core" : true
                        }]
                      }}

      manifest = manifest_from_json_mappings(mappings_json, 'csv')

      expect {
        manifest.apply_to("assay.name\nGX4002")
      }.to raise_error
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

    it "should apply to custom non-pii field" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "temperature",
              "source" : {"lookup" : "temperature"}
            }]
          }
        },
        {json: '{"temperature" : "20"}', csv: "temperature\n20"},
        test: {indexed: Hash.new, pii: Hash.new, custom: {"temperature" => "20"}}
    end

    it "should apply to custom non-pii field coercing to integer" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "temperature",
              "source" : {"lookup" : "temperature"},
              "type" : "integer"
            }]
          }
        },
        {json: '{"temperature" : 20}', csv: "temperature\n20"},
        test: {indexed: Hash.new, pii: Hash.new, custom: {"temperature" => 20}}
    end

    it "should apply to custom non-pii field inside results array" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "assays[*].temperature",
              "source" : {"lookup" : "temperature"}
            }]
          }
        },
        '{"temperature" : 20}',
        test: {indexed: {}, pii: {}, custom: {"assays"=>[{"temperature"=>20}]}}
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

      definition = %{{
        "sample" : [
          {
            "target_field" : "id",
            "source" : {"lookup" : "sample_id"},
            "core" : true
          },
          {
            "target_field" : "type",
            "source" : {"lookup" : "sample_type"},
            "core" : true
          },
          {
            "target_field" : "culture_days",
            "source" : {"lookup" : "culture_days"}
          },
          {
            "target_field" : "datagram",
            "source" : {"lookup" : "datagram"}
          },
          {
            "target_field" : "collected_at",
            "source" : {"lookup" : "collected_at"},
            "pii" : true
          }
        ],
        "patient" : [
          {
            "target_field" : "id",
            "source" : {"lookup" : "patient_id"},
            "pii" : true
          },
          {
            "target_field" : "gender",
            "source" : {"lookup" : "gender"},
            "core" : true
          },
          {
            "target_field" : "dob",
            "source" : {"lookup" : "dob"},
            "pii" : true
          },
          {
            "target_field" : "hiv",
            "source" : {"lookup" : "hiv"}
          },
          {
            "target_field" : "shirt_color",
            "source" : {"lookup" : "shirt_color"}
          }
        ],
        "test" : [
          {
            "target_field" : "id",
            "source" : {"lookup" : "test_id"},
            "core" : true
          },
          {
            "target_field" : "name",
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
            "source" : {"lookup" : "raw_result"}
          },
          {
            "target_field" : "concentration",
            "source" : {"lookup" : "concentration"}
          }
        ]
      }}

      expected = {
        test: {
          indexed: {
            id: "4",
            name: "mtb"
          },
          custom: {
            concentration: "15%",
            raw_result: "positivo 15%"
          },
          pii: {
            start_time: "2000/1/1 10:00:00"
          }
        },
        sample: {
          indexed: {
            id: "4002",
            type: "sputum"
          },
          custom: {
            datagram: "010100011100",
            culture_days: "10"
          },
          pii: {
            collected_at: "2000/1/1 9:00:00"
          }
        },
        patient: {
          indexed: {
            gender: "male"
          },
          pii: {
            id: "8000",
            dob: "2000/1/1"
          },
          custom: {
            hiv: "positive",
            shirt_color: "blue"
          }
        }
      }

      assert_manifest_application definition, {json: test, csv: csv}, expected
    end

    it "should apply to an array of custom field inside assays array" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "assays[*].instant_temperature[*].value",
              "source" : {"lookup" : "tests[*].temperatures[*].value"}
            },
            {
              "target_field" : "assays[*].instant_temperature[*].sample_time",
              "source" : {"lookup" : "tests[*].temperatures[*].time"}
            },
            {
              "target_field" : "assays[*].condition",
              "source" : {"lookup" : "tests[*].condition"},
              "core" : true
            },
            {
              "target_field" : "assays[*].result",
              "source" : {"lookup" : "tests[*].result"},
              "core" : true
            },
            {
              "target_field" : "final_temperature",
              "source" : {"lookup" : "temperature"}
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
        test: {
          indexed: { "assays" => [
            { "condition" => "mtb", "result" => "positive" },
            { "condition" => "rif", "result" => "negative" }
          ]},
          pii: Hash.new,
          custom: {
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
            "test" : [{
              "target_field" : "temperature",
              "source" : {"lookup" : "temperature"},
              "pii" : true
            }]
          }
        },
        '{"temperature" : 20}',
        test: {indexed: Hash.new, pii: {"temperature" => 20}, custom: Hash.new}
    end

    it "doesn't raise on valid value in options" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "level",
              "source" : {"lookup" : "level"},
              "core" : true,
              "options" : ["low", "medium", "high"]
            }]
          }
        },
        '{"level" : "high"}',
        test: {indexed: {"level" => "high"}, pii: Hash.new, custom: Hash.new}
    end

    it "should raise on invalid value in options" do
      assert_raises_manifest_data_validation %{
          {
            "test" : [{
              "target_field" : "level",
              "type" : "enum",
              "source" : {"lookup" : "level"},
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
            "test" : [{
              "target_field" : "temperature",
              "source" : {"lookup" : "temperature"},
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
        test: {indexed: {}, pii: {}, custom: {"temperature" => 30}}
    end

    it "should raise on invalid value in range (lesser)" do
      assert_raises_manifest_data_validation %{
          {
            "test" : [{
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
            "test" : [{
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
            "test" : [{
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
        test: {indexed: {"sample_date" => "2014-05-14T15:22:11+0000"}, pii: Hash.new, custom: Hash.new}
    end

    it "should raise on invalid value in date iso" do
      assert_raises_manifest_data_validation %{
          {
            "test" : [{
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
            "test" : [{
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
        test: {indexed: {"condition" => "MTB"}, pii: Hash.new, custom: Hash.new}
    end

    it "applies second value mapping" do
      assert_manifest_application %{
          {
            "test" : [{
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
        test: {indexed: {"condition" => "H1N1"}, pii: Hash.new, custom: Hash.new}
    end

    it "should raise on mapping not found" do
      assert_raises_manifest_data_validation %{
          {
            "test" : [{
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
            "test" : [{
              "target_field" : "list[*].temperature",
              "source" : {"lookup" : "temperature_list[*].temperature"}
            }]
          }
        },
        '{"temperature_list" : [{"temperature" : 20}, {"temperature" : 10}]}',
        test: {indexed: {}, pii: {}, custom: {"list" => [{"temperature" => 20}, {"temperature" => 10}]}}
    end

    it "should map to multiple indexed fields to the same list" do
      assert_manifest_application %{{
          "test" : [
            {
              "target_field" : "collection[*].temperature",
              "source" : {"lookup" : "some_list[*].temperature"}
            },
            {
              "target_field" : "collection[*].foo",
              "source" : {"lookup" : "some_list[*].bar"}
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
        test: {indexed: {}, pii: Hash.new, custom: {"collection" => [
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
          "test" : [
            {
              "target_field" : "collection[*].temperature",
              "source" : {"lookup" : "temperature_list[*].temperature"},
              "core" : true
            },
            {
              "target_field" : "collection[*].foo",
              "source" : {"lookup" : "other_list[*].bar"},
              "core" : true
            }
          ]
        }},
        '{
          "temperature_list" : [{"temperature" : 20}, {"temperature" : 10}],
          "other_list" : [{"bar" : 10}, {"bar" : 30}, {"bar" : 40}]
        }',
        test: {indexed: {"collection" => [
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

end
