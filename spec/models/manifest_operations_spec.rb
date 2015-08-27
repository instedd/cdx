require 'spec_helper'

describe Manifest, validate_manifest: false do

  context "operations" do

    it "concats two or more elements" do
      assert_manifest_application %{
        {
          "patient.name": {
            "concat" : [
              {"lookup" : "last_name"},
              ", ",
              {"lookup" : "first_name"}
            ]
          }
        }}, %{
          {
          }
        },
        '{
          "first_name" : "John",
          "last_name" : "Doe"
        }',
        "patient" => {"core" => {}, "pii" => {"name" => "Doe, John"}, "custom" => {}}
    end

    it "strips spaces from an element" do
      assert_manifest_application %{
          {
            "patient.name": {
              "concat" : [
                {"strip" : {"lookup" : "last_name"}},
                ", ",
                {"lookup" : "first_name"}
              ]
            }
          }
        },%{
          {
          }
        },
        '{
          "first_name" : "John",
          "last_name" : "   Doe   "
        }',
        "patient" => {"custom" => {}, "pii" => {"name" => "Doe, John"}, "core" => {}}
    end

    it "converts to lowercase" do
      assert_manifest_application %{
        {
          "patient.name": {
            "lowercase": {"lookup" : "last_name" }
          }
        }
      },%{
        {
        }
      },
      %({"last_name" : "Doe"}),
      "patient" => {"custom" => {}, "pii" => {"name" => "doe"}, "core" => {}}
    end

    it "runs javascript" do
      assert_manifest_application %(
        {
          "patient.name": {
            "script": "message.first_name + ' ' + message.last_name"
          }
        }
      ), %(
        {
        }
      ), %({"first_name": "John", "last_name": "Doe"}),
      "patient" => {"custom" => {}, "pii" => {"name" => "John Doe"}, "core" => {}}
    end

    it "has access to device from script" do
      device = Device.make
      assert_manifest_application %(
        {
          "sample.fields": { "script": "device.name + ',' + device.uuid" }
        }
      ), %(
        {
          "sample.fields": {}
        }
      ), %({}),
      {"sample" => {"custom" => {"fields" => "#{device.name},#{device.uuid}"}, "pii" => {}, "core" => {}}}, device
    end

    it "has access to laboratory from script" do
      device = Device.make
      lab = device.laboratory

      assert_manifest_application %(
        {
          "sample.fields": { "script": "laboratory.name + ',' + laboratory.address + ',' + laboratory.city + ',' + laboratory.state + ',' + laboratory.zip_code + ',' + laboratory.country + ',' + laboratory.region + ',' + parseInt(laboratory.lat) + ',' + parseInt(laboratory.lng) + ',' + laboratory.location_geoid" }
        }
      ), %(
        {
          "sample.fields": {}
        }
      ), %({}),
      {"sample" => {"custom" => {"fields" => "#{lab.name},#{lab.address},#{lab.city},#{lab.state},#{lab.zip_code},#{lab.country},#{lab.region},#{lab.lat.to_i},#{lab.lng.to_i},#{lab.location_geoid}"}, "pii" => {}, "core" => {}}}, device
    end

    it "has access to location from script" do
      device = Device.make
      loc = device.laboratory.location

      assert_manifest_application %(
        {
          "sample.fields": { "script": "location.name + ',' + parseInt(location.lat) + ',' + parseInt(location.lng)" }
        }
      ), %(
        {
          "sample.fields": {}
        }
      ), %({}),
      {"sample" => {"custom" => {"fields" => "#{loc.name},#{loc.lat.to_i},#{loc.lng.to_i}"}, "pii" => {}, "core" => {}}}, device
    end

    it "loads xml in javascript" do
      assert_manifest_application %(
        {
          "patient.name": {"script": "message.xpath('Patient/@name').first().value"}
        }
      ), %(
        {
        }
      ), {xml: %(
        <Message>
          <Patient name="Socrates" age="27"/>
        </Message>
      )},
      "patient" => {"custom" => {}, "pii" => {"name" => "Socrates"}, "core" => {}}
    end

    it "maps an array from javascript" do
      assert_manifest_application %(
        {
          "patient.name": {
            "script": "[message.first_name, message.last_name]"
          }
        }
      ), %(
        {
        }
      ), %({"first_name": "John", "last_name": "Doe"}),
      "patient" => {"custom" => {}, "pii" => {"name" => ["John", "Doe"]}, "core" => {}}
    end

    it "maps an array from javascript" do
      assert_raises_manifest_data_validation %(
        {
          "patient.name": {
            "script": "a = {}; a.name = message.first_name; a"
          }
        }
      ), %(
        {
        }
      ), %({"first_name": "John", "last_name": "Doe"}),
      "JSONObject is not a valid return type for 'patient.name' script"
    end

    it "concats the result of a case" do
      assert_manifest_application %{
          {
            "test.foo" : {
              "concat" : [
                {"strip" : {"lookup" : "last_name"}},
                ": ",
                {
                  "case" : [
                    {"lookup" : "test_type"},
                    [
                      { "when" : "*QC*", "then" : "qc"},
                      { "when" : "*Specimen*", "then" : "specimen"}
                    ]
                  ]
                }
              ]
            }
          }
        }, %{
          {
            "test.foo": {}
          }
        },
        '{
          "test_type" : "This is a QC test",
          "last_name" : "   Doe   "
        }',
        "test" => {"custom" => {"foo" => "Doe: qc"}, "pii" => {}, "core" => {}}
    end

    it "does case with then that is a lookup" do
      assert_manifest_application %{
          {
            "test.foo" : {
              "case" : [
                {"lookup" : "test_type"},
                [
                  { "when" : "*QC*", "then" : {"lookup": "last_name"}},
                  { "when" : "*Specimen*", "then" : "specimen"}
                ]
              ]
            }
          }
        }, %{
          {
            "test.foo": {}
          }
        },
        %({
          "test_type" : "This is a QC test",
          "last_name" : "Doe"
        }),
        "test" => {"custom" => {"foo" => "Doe"}, "pii" => {}, "core" => {}}
    end

    it "does case with else" do
      assert_manifest_application %{
          {
            "test.foo" : {
              "case" : [
                {"lookup" : "test_type"},
                [
                  { "when" : "*QC*", "then" : "qc"},
                  { "when" : "*Specimen*", "then" : "specimen"},
                  { "else" : "unknown"}
                ]
              ]
            }
          }
        }, %{
          {
            "test.foo": {}
          }
        },
        %({
          "test_type" : "This won't match"
        }),
        "test" => {"custom" => {"foo" => "unknown"}, "pii" => {}, "core" => {}}
    end

    it "does case with else that is a lookup" do
      assert_manifest_application %{
          {
            "test.foo" : {
              "case" : [
                {"lookup" : "test_type"},
                [
                  { "when" : "*QC*", "then" : "qc"},
                  { "when" : "*Specimen*", "then" : "specimen"},
                  { "else" : {"lookup": "last_name"}}
                ]
              ]
            }
          }
        }, %{
          {
            "test.foo": {}
          }
        },
        %({
          "test_type" : "This won't match",
          "last_name" : "Doe"
        }),
        "test" => {"custom" => {"foo" => "Doe"}, "pii" => {}, "core" => {}}
    end

    it "maps the result of a concat" do
      assert_manifest_application %{
          {
            "test.test_type" : {
              "case" : [
                {
                  "concat" : [
                    {"strip" : {"lookup" : "last_name"}},
                    ": ",
                    {"strip" : {"lookup" : "first_name"}}
                  ]
                },
                [
                  { "when" : "Subject:*", "then" : "specimen"},
                  { "when" : "Doe: John", "then" : "qc"}
                ]
              ]
            }
          }
        }, %{
          {
            "test.test_type": {}
          }
        },
        '{
          "first_name" : " John ",
          "last_name" : "   Doe   "
        }',
        "test" => {"custom" => {"test_type" => "qc"}, "pii" => {}, "core" => {}}
    end

    it "retrieves a substring of an element" do
      assert_manifest_application %{
          {
            "test.test": {
              "substring" : [{"lookup" : "name_and_test"}, 0, 2]
            },
            "test.first_name": {
              "substring" : [{"lookup" : "name_and_test"}, 4, -5]
            }
          }
        }, %{
          {
            "test.test": {},
            "test.first_name": {}
          }
        },
        '{
          "name_and_test" : "ABC John Doe"
        }',
        "test" => {"custom" => {"test" => "ABC", "first_name" => "John"}, "pii" => {}, "core" => {}}
    end

    it "obtains the beginning of the month" do
      assert_manifest_application %{
          {
            "test.month" : {
              "beginning_of" : [
                {"lookup" : "run_at"},
                "month"
              ]
            }
          }
        }, %{
          {
            "test.month": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000"
        }',
        "test" => {"custom" => {"month" => "2014-05-01T00:00:00+0000"}, "pii" => {}, "core" => {}}
    end

    it "parses a strange date" do
      assert_manifest_application %{
          {
            "test.month" : {
              "parse_date" : [
                {"lookup" : "run_at"},
                "%a%d%b%y%H%p%z"
              ]
            }
          }
        }, %{
          {
            "test.month": {}
          }
        },
        '{
          "run_at" : "sat3feb014pm+7"
        }',
        "test" => {"custom" => {"month" => "2001-02-03T16:00:00+0700"}, "pii" => {}, "core" => {}}
    end

    it "parses a date without timezone using the device timezone" do
      assert_manifest_application %{
          {
            "test.month" : {
              "parse_date" : [
                {"lookup" : "run_at"},
                "%a%d%b%y%H%p"
              ]
            }
          }
        }, %{
          {
            "test.month": {}
          }
        },
        '{
          "run_at" : "sat13feb014pm"
        }',
        {"test" => {"custom" => {"month" => "2001-02-13T20:00:00+0000"}, "pii" => {}, "core" => {}}},
        Device.make(time_zone: 'Atlantic Time (Canada)')
    end

    it "obtains the distance in years between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "years_between" : [
                  {"lookup" : "birth_day"},
                  {"lookup" : "run_at"}
                ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 1}, "pii" => {}, "core" => {}}
    end

    it "obtains the distance in months between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "months_between" : [
                {"lookup" : "birth_day"},
                {"lookup" : "run_at"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 13}, "pii" => {}, "core" => {}}
    end

    it "obtains the distance in days between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "days_between" : [
                {"lookup" : "birth_day"},
                {"lookup" : "run_at"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 396}, "pii" => {}, "core" => {}}
    end

    it "obtains the distance in hours between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "hours_between" : [
                {"lookup" : "birth_day"},
                {"lookup" : "run_at"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 9526}, "pii" => {}, "core" => {}}
        # 396 days and 22 hours
    end

    it "obtains the distance in minutes between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "minutes_between" : [
                {"lookup" : "birth_day"},
                {"lookup" : "run_at"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 571618}, "pii" => {}, "core" => {}}
    end

    it "obtains the distance in seconds between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "seconds_between" : [
                {"lookup" : "birth_day"},
                {"lookup" : "run_at"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 34297139}, "pii" => {}, "core" => {}}
    end

    it "obtains the distance in milliseconds between two dates" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "milliseconds_between" : [
                {"lookup" : "birth_day"},
                {"lookup" : "run_at"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 34297139000}, "pii" => {}, "core" => {}}
    end

    it "obtains the distance in milliseconds between two dates disregarding the order" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "milliseconds_between" : [
                {"lookup" : "run_at"},
                {"lookup" : "birth_day"}
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "run_at" : "2014-05-14T15:22:11+0000",
          "birth_day" : "2013-04-12T16:23:11.123+0000"
        }',
        "patient" => {"custom" => {"age" => 34297139000}, "pii" => {}, "core" => {}}
    end

    it "converts from minutes to hours" do
      assert_manifest_application %{
          {
            "patient.age" : {
              "convert_time" : [
                {"lookup" : "age"},
                {"lookup" : "unit"},
                "hours"
              ]
            }
          }
        }, %{
          {
            "patient.age": {}
          }
        },
        '{
          "age" : "90",
          "unit" : "minutes"
        }',
        "patient" => {"custom" => {"age" => 1.5}, "pii" => {}, "core" => {}}
    end

    it "clusterises a number" do
      field_definition = %{
          {
            "patient.age" : {
              "clusterise" : [
                {"lookup" : "age"},
                [5, 20, 40]
              ]
            }
          }
        }

      custom_definition = %{
          {
            "patient.age": {}
          }
      }

      assert_manifest_application field_definition, custom_definition, '{ "age" : "30" }', "patient" => {"custom" => {"age" => "20-40"}, "pii" => {}, "core" => {}}

      assert_manifest_application field_definition, custom_definition,'{ "age" : "90" }', "patient" => {"custom" => {"age" => "40+"}, "pii" => {}, "core" => {}}

      assert_manifest_application field_definition, custom_definition,'{ "age" : "2" }', "patient" => {"custom" => {"age" => "<5"}, "pii" => {}, "core" => {}}

      assert_manifest_application field_definition, custom_definition,'{ "age" : "20.1" }', "patient" => {"custom" => {"age" => "20-40"}, "pii" => {}, "core" => {}}

      assert_manifest_application field_definition, custom_definition,'{ "age" : "20" }', "patient" => {"custom" => {"age" => "5-20"}, "pii" => {}, "core" => {}}

      assert_manifest_application field_definition, custom_definition,'{ "age" : "40" }', "patient" => {"custom" => {"age" => "20-40"}, "pii" => {}, "core" => {}}
    end

    describe "Multiple fields" do

      it "should map single indexed field to a list" do
        assert_manifest_application %{{
            "test.collection[*].temperature" : {"lookup" : "temperature"}
          }}, %{
            {
              "test.collection[*].temperature": {}
            }
          },
          '{
            "temperature" : "20"
          }',
          "test" => {"custom" => {"collection" => [
            {
              "temperature" => "20"
            }]}, "pii" => {}, "core" => {}}
      end

      it "concats two or more elements" do
        expect {
          assert_manifest_application %{
              {
                "patient.results[*].name" : {
                  "concat" : [
                    {"lookup" : "last_name"},
                    ", ",
                    {"lookup" : "conditions[*].name"}
                  ]
                }
              }
            }, %{
              {
                "patient.results[*].name": {}
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
            "patient" => {"custom" => {"results" => [{"name" => "Doe, foo"}, {"name" => "Doe, bar"}]}, "pii" => {}, "core" => {}}
          }.to raise_error("Can't concat array values - use collect instead")
      end

      it "strips spaces from multiple elements" do
        assert_manifest_application %{
            {
              "patient.results[*].name" : {
                "strip" : {"lookup" : "conditions[*].name"}
              }
            }
          }, %{
            {
              "patient.results[*].name": {}
            }
          },
          '{
            "conditions" : [
              {
                "name" : "    foo    "
              },
              {
                "name": "    bar   "
              }
            ]
          }',
          "patient" => {"custom" => {"results" => [{"name" => "foo"}, {"name" => "bar"}]}, "pii" => {}, "core" => {}}
      end

      it "should apply value mapping to multiple indexed field" do
        assert_manifest_application %{
            {
              "test.results[*].condition" : {
                "case" : [
                  {"lookup" : "conditions[*].condition"},
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
              "test.results[*].condition": {}
            }
          },
          '{"conditions" : [{"condition" : "PATIENT HAS MTB CONDITION"}, {"condition" : "PATIENT HAS FLU CONDITION"}]}',
          "test" => {"custom" => {"results" => [{"condition" => "MTB"}, {"condition" => "H1N1"}]}, "pii" => {}, "core" => {}}
      end

      it "retrieves a substring of an element" do
        assert_manifest_application %{
            {
              "test.test" : {
                "substring" : [{"lookup" : "name_and_test"}, 0, 2]
              },
              "test.first_name": {
                "substring" : [{"lookup" : "name_and_test"}, 4, -5]
              }
            }
          }, %{
            {
              "test.test": {},
              "test.first_name": {}
            }
          },
          '{
            "name_and_test" : "ABC John Doe"
          }',
          "test" => {"custom" => {"test" => "ABC", "first_name" => "John"}, "pii" => {}, "core" => {}}
      end

      it "obtains the beginning of the month" do
        assert_manifest_application %{
            {
              "test.month" : {
                "beginning_of" : [
                  {"lookup" : "run_at"},
                  "month"
                ]
              }
            }
          }, %{
            {
              "test.month": {}
            }
          },
          '{
            "run_at" : "2014-05-14T15:22:11+0000"
          }',
          "test" => {"custom" => {"month" => "2014-05-01T00:00:00+0000"}, "pii" => {}, "core" => {}}
      end

      it "parses an strange date" do
        assert_manifest_application %{
            {
              "test.month" : {
                "parse_date" : [
                  {"lookup" : "run_at"},
                  "%a%d%b%y%H%p%z"
                ]
              }
            }
          }, %{
            {
              "test.month": {}
            }
          },
          '{
            "run_at" : "sat3feb014pm+7"
          }',
          "test" => {"custom" => {"month" => "2001-02-03T16:00:00+0700"}, "pii" => {}, "core" => {}}
      end

      it "should count years between multiple indexed fields" do
        assert_manifest_application %{
            {
              "test.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "years_between" : [
                      {"lookup" : "run_at"},
                      {"lookup" : "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "test" => {"custom" => {"results" => [{"age" => 1}, {"age" => 1}]}, "pii" => {}, "core" => {}}
      end

      it "should count years between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "years_between" : [
                      {"lookup" : "$.birth_day"},
                      {"lookup" : "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 1}, {"age" => 1}]}, "pii" => {}, "core" => {}}
      end

      it "should count years between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "years_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 1}, {"time" => 1}]}, "pii" => {}, "core" => {}}
      end

      it "should count months between multiple indexed fields" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "months_between": [
                      {"lookup" : "run_at"},
                      {"lookup" : "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 13}, {"age" => 13}]}, "pii" => {}, "core" => {}}
      end

      it "should count months between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "months_between": [
                      {"lookup": "$.birth_day"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 13}, {"age" => 13}]}, "pii" => {}, "core" => {}}
      end

      it "should count months between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "months_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 13}, {"time" => 13}]}, "pii" => {}, "core" => {}}
      end

      it "should count days between multiple indexed fields" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "days_between": [
                      {"lookup": "run_at"},
                      {"lookup": "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 396}, {"age" => 397}]}, "pii" => {}, "core" => {}}
      end

      it "should count days between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "days_between": [
                      {"lookup": "$.birth_day"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          {
            json: '{
              "birth_day" : "2013-04-12T16:23:11.123+0000",
              "conditions" : [
                {"run_at" : "2014-05-14T15:22:11+0000"},
                {"run_at" : "2014-05-15T15:22:11+0000"}
              ]
            }'
          },
          "patient" => {"custom" => {"results" => [{"age" => 396}, {"age" => 397}]}, "pii" => {}, "core" => {}}
      end

      it "should count days between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "days_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
                "end_time" : "2013-04-11T16:23:11.123+0000"
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 396}, {"time" => 398}]}, "pii" => {}, "core" => {}}
      end

      it "should count hours between multiple indexed fields" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "hours_between": [
                      {"lookup": "run_at"},
                      {"lookup": "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 9526}, {"age" => 9550}]}, "pii" => {}, "core" => {}}
      end

      it "should count hours between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "hours_between": [
                      {"lookup": "$.birth_day"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 9526}, {"age" => 9550}]}, "pii" => {}, "core" => {}}
      end

      it "should count hours between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "hours_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 9526}, {"time" => 9526}]}, "pii" => {}, "core" => {}}
      end

      it "should count minutes between multiple indexed fields" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "minutes_between": [
                      {"lookup": "run_at"},
                      {"lookup": "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 571618}, {"age" => 573058}]}, "pii" => {}, "core" => {}}
      end

      it "should count minutes between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "minutes_between": [
                      {"lookup": "$.birth_day"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 571618}, {"age" => 573058}]}, "pii" => {}, "core" => {}}
      end

      it "should count minutes between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "minutes_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 571618}, {"time" => 571618}]}, "pii" => {}, "core" => {}}
      end

      it "should count seconds between multiple indexed fields" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "seconds_between": [
                      {"lookup": "run_at"},
                      {"lookup": "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 34297139}, {"age" => 34383539}]}, "pii" => {}, "core" => {}}
      end

      it "should count seconds between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "seconds_between": [
                      {"lookup": "$.birth_day"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 34297139}, {"age" => 34383539}]}, "pii" => {}, "core" => {}}
      end

      it "should count seconds between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "seconds_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 34297139}, {"time" => 34297139}]}, "pii" => {}, "core" => {}}
      end

      it "should count milliseconds between multiple indexed fields" do
        assert_manifest_application %{
            {
              "patient.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "milliseconds_between": [
                      {"lookup": "run_at"},
                      {"lookup": "$.birth_day"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "patient.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "patient" => {"custom" => {"results" => [{"age" => 34297139000}, {"age" => 34383539000}]}, "pii" => {}, "core" => {}}
      end

      it "should count milliseconds between multiple indexed fields on the second parameter" do
        assert_manifest_application %{
            {
              "test.results[*].age" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "milliseconds_between": [
                      {"lookup": "$.birth_day"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].age": {}
            }
          },
          '{
            "birth_day" : "2013-04-12T16:23:11.123+0000",
            "conditions" : [
              {"run_at" : "2014-05-14T15:22:11+0000"},
              {"run_at" : "2014-05-15T15:22:11+0000"}
            ]}',
          "test" => {"custom" => {"results" => [{"age" => 34297139000}, {"age" => 34383539000}]}, "pii" => {}, "core" => {}}
      end

      it "should count milliseconds between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test.results[*].time" : {
                "map": [
                  {"lookup": "conditions"},
                  {
                    "milliseconds_between": [
                      {"lookup": "end_time"},
                      {"lookup": "run_at"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].time": {}
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
              }
            ]}',
          "test" => {"custom" => {"results" => [{"time" => 34297139000}, {"time" => 34297139000}]}, "pii" => {}, "core" => {}}
      end

      it "converts from minutes to hours" do
        assert_manifest_application %{
            {
              "test.results[*].age" : {
                "map": [
                  {"lookup": "multiple"},
                  {
                    "convert_time": [
                      {"lookup": "age"},
                      {"lookup": "$.unit"},
                      "hours"
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].age": {}
            }
          },
          '{
            "multiple" : [
              {"age" : "90"},
              {"age" : "60"}
            ],
            "unit" : "minutes"
          }',
          "test" => {"custom" => {"results" => [{"age" => 1.5}, {"age" => 1}]}, "pii" => {}, "core" => {}}
      end

      it "clusterises an array of numbers" do
        field_definition = %{
            {
              "test.results[*].age" : {
                "clusterise" : [
                    {"lookup" : "multiple[*].age"},
                    [5, 20, 40]
                  ]
              }
            }
          }

        custom_definition = '{"test.results[*].age": {}}'

        assert_manifest_application field_definition, custom_definition,
          '{
            "multiple" : [
              {"age" : "30"},
              {"age" : "90"},
              {"age" : "2"},
              {"age" : "20.1"},
              {"age" : "20"},
              {"age" : "40"}
            ]
          }',

          {
            "test" => {
              "custom" => {
                "results" => [
                  {"age" => "20-40"},
                  {"age" => "40+"},
                  {"age" => "<5"},
                  {"age" => "20-40"},
                  {"age" => "5-20"},
                  {"age" => "20-40"}
                ]
              },
              "pii" => {},
              "core" => {}
            },
            "patient" => { "core" => {}, "pii" => {}, "custom" => {} },
            "sample" => { "core" => {}, "pii" => {}, "custom" => {} }
          }


      end

      it "should collect elements in an XML file" do
        assert_manifest_application %{
            {
              "test.results[*].assay_code" : {
                "map": [
                  {"lookup": "Test/Assay"},
                  {
                    "concat" : [
                      {"lookup" : "/Test/@type"},
                      " - ",
                      {"lookup" : "@code"}
                    ]
                  }
                ]
              }
            }
          }, %{
            {
              "test.results[*].assay_code": {}
            }
          },
          { xml: '
            <Message>
              <Test type="some_type">
                <Assay code="flu-a">
                  <Result>positive</Result>
                </Assay>
                <Assay code="flu-b">
                  <Result>negative</Result>
                </Assay>
              </Test>
            </Message>
          ' },
          "test" => {"custom" => {"results" => [{"assay_code" => "some_type - flu-a"}, {"assay_code" => "some_type - flu-b"}]}, "pii" => {}, "core" => {}}
      end

    end

  end

end
