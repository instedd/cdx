require 'spec_helper'

describe Manifest, validate_manifest: false do

  context "operations" do

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

    it "converts to lowercase" do
      assert_manifest_application %(
        {
          "patient": [{
            "target_field" : "name",
            "source": {
              "lowercase": {"lookup" : "last_name" }
            },
            "core": true,
            "pii": false,
            "indexed": true
          }]
        }
      ), %({"last_name" : "Doe"}),
      patient: {indexed: {"name" => "doe"}, pii: {}, custom: {}}
    end

    it "runs javascript" do
      assert_manifest_application %(
        {
          "patient": [{
            "target_field": "name",
            "source": {
              "script": "event.first_name + ' ' + event.last_name"
            },
            "core": true,
            "pii": false,
            "indexed": true
          }]
        }
      ), %({"first_name": "John", "last_name": "Doe"}),
      patient: {indexed: {"name" => "John Doe"}, pii: {}, custom: {}}
    end

    it "loads xml in javascript" do
      assert_manifest_application %(
        {
          "patient": [{
            "target_field": "name",
            "source": {
              "script": "event.xpath('Patient/@name').first().value"
            },
            "core": true,
            "indexed": true
          }]
        }
      ), {xml: %(<Events>
        <Event>
          <Patient name="Socrates" age="27"/>
        </Event>
      </Events>)},
      patient: {indexed: {"name" => "Socrates"}, pii: {}, custom: {}}
    end

    it "concats the result of a mapping" do
      assert_manifest_application %{
          {
            "test" : [{
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
        test: {indexed: {"foo" => "Doe: qc"}, pii: Hash.new, custom: Hash.new}
    end

    it "maps the result of a concat" do
      assert_manifest_application %{
          {
            "test" : [{
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
        test: {indexed: {"test_type" => "qc"}, pii: Hash.new, custom: Hash.new}
    end

    it "retrieves a substring of an element" do
      assert_manifest_application %{
          {
            "test" : [
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
        test: {indexed: {"test" => "ABC", "first_name" => "John"}, pii: Hash.new, custom: Hash.new}
    end

    it "obtains the beginning of the month" do
      assert_manifest_application %{
          {
            "test" : [{
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
        test: {indexed: {"month" => "2014-05-01T00:00:00+0000"}, pii: Hash.new, custom: Hash.new}
    end

    it "parses a strange date" do
      assert_manifest_application %{
          {
            "test" : [{
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
        test: {indexed: {"month" => "2001-02-03T16:00:00+0700"}, pii: Hash.new, custom: Hash.new}
    end

    it "parses a date without timezone using the device timezone" do
      assert_manifest_application %{
          {
            "test" : [{
              "target_field" : "month",
              "source" : {
                "parse_date" : [
                  {"lookup" : "run_at"},
                  "%a%d%b%y%H%p"
                ]
              },
              "core" : true,
              "pii" : false,
              "indexed" : true
            }]
          }
        },
        '{
          "run_at" : "sat13feb014pm"
        }',
        {test: {indexed: {"month" => "2001-02-13T20:00:00+0000"}, pii: Hash.new, custom: Hash.new}},
        Device.make(time_zone: 'Atlantic Time (Canada)')
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
            "test" : [
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
          test: {indexed: {"collection" => [
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
              "test" : [{
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
          test: {indexed: {"results" => [{"condition" => "MTB"}, {"condition" => "H1N1"}]}, pii: Hash.new, custom: Hash.new}
      end

      it "retrieves a substring of an element" do
        assert_manifest_application %{
            {
              "test" : [
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
          test: {indexed: {"test" => "ABC", "first_name" => "John"}, pii: Hash.new, custom: Hash.new}
      end

      it "obtains the beginning of the month" do
        assert_manifest_application %{
            {
              "test" : [{
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
          test: {indexed: {"month" => "2014-05-01T00:00:00+0000"}, pii: Hash.new, custom: Hash.new}
      end

      it "parses an strange date" do
        assert_manifest_application %{
            {
              "test" : [{
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
          test: {indexed: {"month" => "2001-02-03T16:00:00+0700"}, pii: Hash.new, custom: Hash.new}
      end

      it "should count years between multiple indexed fields" do
        assert_manifest_application %{
            {
              "test" : [{
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
          test: {indexed: {"results" => [{"age" => 1}, {"age" => 1}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"time" => 1}, {"time" => 1}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"time" => 396}, {"time" => 398}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"time" => 396}, {"time" => 398}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"time" => 9526}, {"time" => 9526}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"time" => 571618}, {"time" => 571618}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"time" => 34297139}, {"time" => 34297139}]}, pii: Hash.new, custom: Hash.new}
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
              "test" : [{
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
          test: {indexed: {"results" => [{"age" => 34297139877000}, {"age" => 34297139877000}]}, pii: Hash.new, custom: Hash.new}
      end

      it "should count milliseconds between multiple indexed fields on both parameters" do
        assert_manifest_application %{
            {
              "test" : [{
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
              "test" : [{
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
              "test" : [{
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

end
