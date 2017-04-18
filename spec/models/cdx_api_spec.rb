require 'spec_helper'

describe Cdx::Api, elasticsearch: true do
  include_context "cdx api helpers"

  let!(:device) {Device.make}
  let!(:institution) { device.institution }

  describe "Filter" do
    it "should check for new tests since a date" do
      index test: {assays: [result: :positive], start_time: time(2013, 1, 1)}
      index test: {assays: [result: :negative], start_time: time(2013, 1, 2)}

      response = query_tests("since" => time(2013, 1, 2))

      expect(response.size).to eq(1)
      expect(response.first["test"]["assays"].first["result"]).to eq("negative")

      response = query_tests("since" => time(2013, 1, 1)).sort_by do |test|
        test["test"]["assays"].first["result"]
      end

      expect(response.first["test"]["assays"].first["result"]).to eq("negative")
      expect(response.last["test"]["assays"].first["result"]).to eq("positive")

      expect(query_tests("since" => time(2013, 1, 3))).to be_empty
    end

    it "should check for new tests since a date in a differen time zone" do
      Time.zone = ActiveSupport::TimeZone["Asia/Seoul"]

      index test: {assays: [result: :positive], start_time: 3.day.ago.change(:hour => 12).iso8601}
      index test: {assays: [result: :negative], start_time: 1.day.ago.change(:hour => 12).iso8601}

      response = query_tests("since" => 2.day.ago.change(:hour => 12).iso8601)

      expect(response.size).to eq(1)
      expect(response.first["test"]["assays"].first["result"]).to eq("negative")

      response = query_tests("since" => 4.day.ago.change(:hour => 12).iso8601).sort_by do |test|
        test["test"]["assays"].first["result"]
      end

      expect(response.first["test"]["assays"].first["result"]).to eq("negative")
      expect(response.last["test"]["assays"].first["result"]).to eq("positive")

      expect(query_tests("since" => Date.current.change(:hour => 12).iso8601)).to be_empty
    end

    it "should asume current timezone if no one is provided" do
      Time.zone = ActiveSupport::TimeZone["Asia/Seoul"]

      index test: {assays: [result: :negative], start_time: Time.zone.local(2010, 10, 10, 01, 00, 30).iso8601}

      response = query_tests("since" => '2010-10-10T01:00:29')

      expect(response.size).to eq(1)
      expect(response.first["test"]["assays"].first["result"]).to eq("negative")
    end

    it "should check for new tests util a date" do
      index test: {assays: [result: :positive], start_time: time(2013, 1, 1)}
      index test: {assays: [result: :negative], start_time: time(2013, 1, 3)}

      expect_one_result "positive", "until" => time(2013, 1, 2)
    end

    it 'filters by reported_time_since and reported_time_until' do
      index test: {
        assays: [result: :positive],
        reported_time: time(2013, 1, 1)
      }
      index test: {
        assays: [result: :positive],
        reported_time: time(2013, 1, 3)
      }
      query = {
        'test.reported_time_since' => time(2013, 1, 2),
        'test.reported_time_until' => time(2013, 1, 3)
      }

      expect_one_result 'positive', query
    end

    [
      ['test.name', :'name', ["GX4001", "GX1234", "GX9999"]],
      ['test.uuid', :'uuid', ["1234", "5678", "9012"]],
    ].each do |query_name, index_name, values|
      it "should filter by #{query_name}" do
        index test: {assays: [result: :positive], index_name => values[0]}
        index test: {assays: [result: :negative], index_name => values[1]}

        expect_one_result "positive", query_name => values[0]
        expect_one_result "negative", query_name => values[1]
        expect_no_results query_name => values[2]
      end
    end

    it "should filter by test.patient_age, making sure in_millis is automatically created" do
      index_with_test_result test: {assays: [result: :positive]}, encounter: {"patient_age" => {years: 10}}
      index_with_test_result test: {assays: [result: :negative]}, encounter: {"patient_age" => {years: 15}}

      expect_one_result "positive", "encounter.patient_age" => "..10yo"
      expect_one_result "negative", "encounter.patient_age" => "12yo..18yo"
      expect_no_results "encounter.patient_age" => "20yo.."
    end
    
    it "should filter by test.user_mail" do
      index_with_test_result test: {assays: [result: :positive]}, encounter: {user_email: institution.user.email}
      expect_one_result "positive", "encounter.user_email" => institution.user.email
    end

    [
      ['device.uuid', 'device.uuid', ["dev1", "dev2", "dev3"]],
      ['site.uuid', 'site.uuid', ["1", "2", "3"]],
      ['institution.uuid', 'institution.uuid', ["1", "2", "3"]],
      ['patient.gender', 'patient.gender', ["male", "female", "unknown"]],
    ].each do |query_name, index_name, values|
      it "should filter by #{query_name}" do
        index test: {assays: [result: :positive]}, index_name => values[0]
        index test: {assays: [result: :negative]}, index_name => values[1]

        expect_one_result "positive", query_name => values[0]
        expect_one_result "negative", query_name => values[1]
        expect_no_results query_name => values[2]
      end
    end

    it "filters by site_user" do
      index test: {site_user: "jdoe"}
      index test: {site_user: "mmajor"}

      expect_one_event_with_field "test", "site_user", "jdoe", 'test.site_user' => "jdoe"
      expect_one_event_with_field "test", "site_user", "mmajor", 'test.site_user' => "mmajor"
      expect_no_results "test.site_user" => "ffoo"
    end

    it "filters by min age" do
      index_with_test_result test: {assays: [result: :positive]}, encounter: {patient_age: {years: 10}}
      index_with_test_result test: {assays: [result: :negative]}, encounter: {patient_age: {years: 20}}

      expect_one_result "negative", "encounter.patient_age" => "15yo.."
      expect_one_result "negative", "encounter.patient_age" => "20yo.."
      expect_no_results "encounter.patient_age" => "21yo.."
    end

    it "filters by max age" do
      index test: {assays: [result: :positive]}, encounter: {"uuid" => "1234", patient_age: Cdx::Field::DurationField.years(10)}
      index test: {assays: [result: :negative]}, encounter: {"uuid" => "1234", patient_age: Cdx::Field::DurationField.years(20)}

      expect_one_result "positive", "encounter.patient_age" => "..15yo"
      expect_one_result "positive", "encounter.patient_age" => "..10yo"
      expect_no_results "encounter.patient_age" => "..9yo"
    end

    it "filters by result" do
      index test: {assays:[name: "MTB", result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}
      index test: {assays:[name: "Flu", result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}

      expect_one_event_with_field "encounter", "patient_age", Cdx::Field::DurationField.years(10), "test.assays.result" => :positive
      expect_one_event_with_field "encounter", "patient_age", Cdx::Field::DurationField.years(20), "test.assays.result" => :negative
    end

    it "filters by a partial match" do
      index test: {assays:[result: :positive], name: "GX4001"}
      index test: {assays:[result: :negative], name: "GX1234"}

      expect_one_result "negative", 'test.name' => "GX1*"
      expect_one_result "positive", 'test.name' => "GX4*"
      expect_no_results 'test.name' => "GX5*"
    end

    it "filters by assay name" do
      index test: {assays:[name: "MTB", result: :positive]}
      index test: {assays:[name: "Flu", result: :negative]}

      expect_one_result "positive", 'test.assays.name' => "MTB"
      expect_one_result "negative", 'test.assays.name' => "Flu"
      expect_no_results 'test.assays.name' => "Qux"
    end

    it "filters by result, age and name" do
      index test: {assays:[name: "MTB", result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index test: {assays:[name: "MTB", result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index test: {assays:[name: "Flu", result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}

      expect_one_result "negative", 'test.assays.result' => :negative, 'encountre.patient_age' => "..20yo", 'test.assays.name' => "Flu"
    end

    it "filters by test type" do
      index test: {assays:[name: "MTB", result: :positive], type: :qc}
      index test: {assays:[name: "MTB", result: :negative], type: :specimen}

      expect_one_result "negative", 'test.type' => :specimen
    end

    it "filters by error code, one result expected" do
      index test: {error_code: 1}
      index test: {error_code: 2}

      expect_one_event_with_field "test", "error_code", 1, 'test.error_code' => 1
      expect_no_results 'test.error_code' => 3
    end



    describe "Multi" do
      it "filters by multiple genders with array" do
        index test: {patient_age: {years: 1}}, patient: {gender: "male"}
        index test: {patient_age: {years: 2}}, patient: {gender: "female"}
        index test: {patient_age: {years: 3}}, patient: {gender: "unknown"}

        response = query_tests('patient.gender' => ["male", "female"]).sort_by do |test|
          Cdx::Field::DurationField.convert_time test["test"]["patient_age"]
        end

        expect(response).to eq([
          {'test' => {"patient_age" => {"years" => 1}}, 'patient' => {"gender" => "male"}},
          {'test' => {"patient_age" => {"years" => 2}}, 'patient' => {"gender" => "female"}}
        ])
      end

      it "filters by multiple genders with comma" do
        index test: {patient_age: {years: 1}}, patient: {gender: "male"}
        index test: {patient_age: {years: 2}}, patient: {gender: "female"}
        index test: {patient_age: {years: 3}}, patient: {gender: "unknown"}

        response = query_tests('patient.gender' => "male,female").sort_by do |test|
          Cdx::Field::DurationField.convert_time test["test"]["patient_age"]
        end

        expect(response).to eq([
          {"test" => {"patient_age" => { "years" => 1 } }, "patient" => {"gender" => "male"}},
          {"test" => {"patient_age" => { "years" => 2 } }, "patient" => {"gender" => "female"}},
        ])
      end

      it "filters by multiple test types with array" do
        index test: {patient_age: {years: 1}, type: "one"}
        index test: {patient_age: {years: 2}, type: "two"}
        index test: {patient_age: {years: 3}, type: "three"}

        response = query_tests('test.type' => ["one", "two"]).sort_by do |test|
          test["test"]["type"]
        end

        expect(response).to eq([
          {"test" => {"patient_age" => { "years" => 1} , "type" => "one"}},
          {"test" => {"patient_age" => { "years" => 2} , "type" => "two"}},
        ])
      end

      it "filters by multiple test types with comma" do
        index test: {patient_age: {years: 1}, type: "one"}
        index test: {patient_age: {years: 2}, type: "two"}
        index test: {patient_age: {years: 3}, type: "three"}

        response = query_tests('test.type' => "one,two").sort_by do |test|
          test["test"]["type"]
        end

        expect(response).to eq([
          {"test" => {"patient_age" => { "years" => 1 }, "type" => "one"}},
          {"test" => {"patient_age" => { "years" => 2 }, "type" => "two"}},
        ])
      end

      it "filters by null value" do
        index test: {assays:[result: :positive], patient_age: {years: 10}}
        index test: {assays:[name: "Flu", result: :negative], patient_age: {years: 20}}
        index test: {assays:[name: "MTB", result: :negative], patient_age: {years: 30}}

        expect_one_result "positive", 'test.assays.name' => 'null'

        response = query_tests('test.assays.name' => "null,MTB").sort_by do |test|
          Cdx::Field::DurationField.convert_time test["test"]["patient_age"]
        end

        expect(response).to eq([
          {"test" => {"patient_age" => { "years" => 10 }, "assays" => ["result" => "positive"]}},
          {"test" => {"patient_age" => { "years" => 30 }, "assays" => ["name" => "MTB", "result" => "negative"]}}
        ])
      end

      it "filters by not(null) value" do
        index test: {assays:[result: :positive], patient_age: {years: 10}}
        index test: {assays:[name: "Flu", result: :negative], patient_age: {years: 20}}
        index test: {assays:[name: "MTB", result: :negative], patient_age: {years: 30}}

        response = query_tests('test.assays.name' => "not(null)").sort_by do |test|
          Cdx::Field::DurationField.convert_time test["test"]["patient_age"]
        end

        expect(response).to eq([
          {"test" => {"patient_age" => { "years" => 20 }, "assays" => ["name" => "Flu", "result" => "negative"]}},
          {"test" => {"patient_age" => { "years" => 30 }, "assays" => ["name" => "MTB", "result" => "negative"]}}
        ])
      end
    end
  end

  describe "Grouping" do
    it "groups by gender" do
      index test: {assays:[result: :positive]}, patient: {gender: :male}
      index test: {assays:[result: :negative]}, patient: {gender: :male}
      index test: {assays:[result: :negative]}, patient: {gender: :female}

      response = query_tests("group_by" => 'patient.gender').sort_by do |test|
        test["patient.gender"]
      end

      expect(response).to eq([
        {"patient.gender" => "female", "count" => 1},
        {"patient.gender" => "male",   "count" => 2}
      ])
    end

    it "groups by gender and assay_name" do
      index test: {assays:[result: :positive], name: "a"}, patient: {gender: :male}
      index test: {assays:[result: :positive], name: "a"}, patient: {gender: :male}
      index test: {assays:[result: :positive], name: "b"}, patient: {gender: :male}
      index test: {assays:[result: :negative], name: "a"}, patient: {gender: :female}
      index test: {assays:[result: :negative], name: "b"}, patient: {gender: :female}
      index test: {assays:[result: :negative], name: "b"}, patient: {gender: :female}

      response = query_tests("group_by" => "patient.gender,test.name").sort_by do |test|
        test["patient.gender"] + test["test.name"]
      end

      expect(response).to eq([
        {"patient.gender"=>"female", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"female", "test.name" => "b", "count" => 2},
        {"patient.gender"=>"male", "test.name" => "a", "count" => 2},
        {"patient.gender"=>"male", "test.name" => "b", "count" => 1}
      ])
    end

    it "groups by test type" do
      index test: {assays:[result: :positive], type: "qc"}
      index test: {assays:[result: :positive], type: "specimen"}
      index test: {assays:[result: :positive], type: "qc"}

      response = query_tests("group_by" => "test.type").sort_by do |test|
        test["test.type"]
      end

      expect(response).to eq([
        {"test.type"=>"qc", "count" => 2},
        {"test.type"=>"specimen", "count" => 1},
      ])
    end

    it "groups by gender, assay_name and result" do
      index test: {assays:[result: :positive], name: "a"}, patient: {gender: :male}
      index test: {assays:[result: :negative], name: "a"}, patient: {gender: :male}
      index test: {assays:[result: :positive], name: "b"}, patient: {gender: :male}
      index test: {assays:[result: :negative], name: "a"}, patient: {gender: :female}
      index test: {assays:[result: :negative], name: "b"}, patient: {gender: :female}
      index test: {assays:[result: :negative], name: "b"}, patient: {gender: :female}

      response = query_tests("group_by" => "patient.gender,test.name,test.assays.result").sort_by do |test|
        test["patient.gender"] + test["test.assays.result"] + test["test.name"]
      end

      expect(response).to eq([
        {"patient.gender"=>"female", "test.assays.result" => "negative", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"female", "test.assays.result" => "negative", "test.name" => "b", "count" => 2},
        {"patient.gender"=>"male", "test.assays.result" => "negative", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"male", "test.assays.result" => "positive", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"male", "test.assays.result" => "positive", "test.name" => "b", "count" => 1}
      ])
    end

    it "groups by gender, assay_name and result in a different order" do
      index test: {assays:[result: :positive], name: "a"}, patient: {gender: :male}
      index test: {assays:[result: :negative], name: "a"}, patient: {gender: :male}
      index test: {assays:[result: :positive], name: "b"}, patient: {gender: :male}
      index test: {assays:[result: :negative], name: "a"}, patient: {gender: :female}
      index test: {assays:[result: :negative], name: "b"}, patient: {gender: :female}
      index test: {assays:[result: :negative], name: "b"}, patient: {gender: :female}

      response = query_tests("group_by" => "test.assays.result,patient.gender,test.name").sort_by do |test|
        test["patient.gender"] + test["test.assays.result"] + test["test.name"]
      end

      expect(response).to eq([
        {"patient.gender"=>"female", "test.assays.result" => "negative", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"female", "test.assays.result" => "negative", "test.name" => "b", "count" => 2},
        {"patient.gender"=>"male", "test.assays.result" => "negative", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"male", "test.assays.result" => "positive", "test.name" => "a", "count" => 1},
        {"patient.gender"=>"male", "test.assays.result" => "positive", "test.name" => "b", "count" => 1}
      ])
    end

    it "groups by system user" do
      index test: {site_user: "jdoe"}
      index test: {site_user: "jdoe"}
      index test: {site_user: "mmajor"}
      index test: {site_user: "mmajor"}

      response = query_tests("group_by" => "test.site_user").sort_by do |test|
        test["test.site_user"]
      end

      expect(response).to eq([
        {"test.site_user"=>"jdoe", "count" => 2},
        {"test.site_user"=>"mmajor", "count" => 2},
      ])
    end

    it "raises exception when interval is not supported" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 1)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 2)}
      index test: {assays:[result: :positive], reported_time: time(2011, 1, 1)}

      expect {
        query_tests("group_by" => "foo(test.reported_time)")
      }.to raise_error("Unsupported group")
    end

    it "groups by year(date)" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 1)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 2)}
      index test: {assays:[result: :positive], reported_time: time(2011, 1, 1)}

      response = query_tests("group_by" => "year(test.reported_time)").sort_by do |test|
        test["test.reported_time"]
      end

      expect(response).to eq([
        {"test.reported_time"=>"2010", "count" => 2},
        {"test.reported_time"=>"2011", "count" => 1}
      ])
    end

    it "groups by month(date)" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 1)}
      index test: {assays:[result: :positive], reported_time: time(2010, 2, 2)}
      index test: {assays:[result: :positive], reported_time: time(2011, 1, 1)}
      index test: {assays:[result: :positive], reported_time: time(2011, 1, 2)}
      index test: {assays:[result: :positive], reported_time: time(2011, 2, 1)}

      response = query_tests("group_by" => "month(test.reported_time)").sort_by do |test|
        test["test.reported_time"]
      end

      expect(response).to eq([
        {"test.reported_time"=>"2010-01", "count" => 1},
        {"test.reported_time"=>"2010-02", "count" => 1},
        {"test.reported_time"=>"2011-01", "count" => 2},
        {"test.reported_time"=>"2011-02", "count" => 1}
      ])
    end

    it "groups by week(date)" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 5)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 6)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 12)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 13)}
      index test: {assays:[result: :positive], reported_time: time(2010, 6, 13)}

      response = query_tests("group_by" => "week(test.reported_time)").sort_by do |test|
        test["test.reported_time"]
      end

      expect(response).to eq([
        {"test.reported_time"=>"2010-W01", "count" => 3},
        {"test.reported_time"=>"2010-W02", "count" => 2},
        {"test.reported_time"=>"2010-W23", "count" => 1},
      ])
    end

    it "groups by week(date) and uses weekyear" do
      index test: {reported_time: time(2012, 12, 31)}

      response = query_tests("group_by" => "week(test.reported_time)")

      expect(response).to eq([
        {"test.reported_time"=>"2013-W01", "count" => 1},
      ])
    end

    it "groups by day(date)" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 5)}

      response = query_tests("group_by" => "day(test.reported_time)").sort_by do |test|
        test["test.reported_time"]
      end

      expect(response).to eq([
        {"test.reported_time"=>"2010-01-04", "count" => 3},
        {"test.reported_time"=>"2010-01-05", "count" => 1}
      ])
    end

    it "groups by day(date) and result" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :negative], reported_time: time(2010, 1, 4)}
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 5)}

      response = query_tests("group_by" => "day(test.reported_time),test.assays.result").sort_by do |test|
        test["test.reported_time"] + test["test.assays.result"]
      end

      expect(response).to eq([
        {"test.reported_time"=>"2010-01-04", "test.assays.result" => "negative", "count" => 1},
        {"test.reported_time"=>"2010-01-04", "test.assays.result" => "positive", "count" => 2},
        {"test.reported_time"=>"2010-01-05", "test.assays.result" => "positive", "count" => 1}
      ])
    end

    it "groups by age ranges" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(9)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(10)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(11)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(12)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(13)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(21)}

      response = query_tests("group_by" => [{"encounter.patient_age" => ["..10yo", "15yo..", "10yo..15yo"]}]).sort_by do |test|
        test["encounter.patient_age"]
      end

      expect(response).to eq([
        {"encounter.patient_age"=>"..10yo", "count" => 1},
        {"encounter.patient_age"=>"10yo..15yo", "count" => 4},
        {"encounter.patient_age"=>"15yo..", "count" => 2}
      ])
    end

    it "groups by age ranges using hashes" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(9)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(10)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(11)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(12)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(13)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(21)}

      response = query_tests("group_by" => [{"encounter.patient_age" => ["..10yo", "10yo..15yo", "16yo..21yo", "21yo.."]}]).sort_by do |test|
        test["encounter.patient_age"]
      end

      expect(response).to eq([
        {"encounter.patient_age"=>"..10yo", "count" => 1},
        {"encounter.patient_age"=>"10yo..15yo", "count" => 4},
        {"encounter.patient_age"=>"16yo..21yo", "count" => 1},
        {"encounter.patient_age"=>"21yo..", "count" => 1}
      ])
    end

    it "groups by age ranges without the array" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(9)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(10)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(11)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(12)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(13)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(21)}

      response = query_tests("group_by" => {"encounter.patient_age" => ["..10yo", "15yo..120yo", "10yo..15yo"]}).sort_by do |test|
        test["encounter.patient_age"]
      end

      expect(response).to eq([
        {"encounter.patient_age"=>"..10yo", "count" => 1},
        {"encounter.patient_age"=>"10yo..15yo", "count" => 4},
        {"encounter.patient_age"=>"15yo..120yo", "count" => 2}
      ])
    end

    it "groups by assays result" do
      index test: {assays:[
        {name: "MTB", result: :positive},
        {name: "Flu", result: :negative},
      ]}

      response = query_tests("group_by" => "test.assays.result").sort_by do |test|
        test["test.assays.result"]
      end

      expect(response).to eq([
        {"test.assays.result"=>"negative", "count" => 1},
        {"test.assays.result"=>"positive", "count" => 1}
      ])
    end

    it 'groups by assays result and name' do
      index test: {
        assays: [
          { name: 'MTB', result: :positive },
          { name: 'Flu', result: :negative }
        ]
      }

      response = query_tests(
        'group_by' => 'test.assays.result,test.assays.name'
      ).sort_by do |test|
        test['test.assays.result'] + test['test.assays.name']
      end

      expect(response).to eq([
        {
          'test.assays.result' => 'negative',
          'test.assays.name' => 'Flu',
          'count' => 1
        },
        {
          'test.assays.result' => 'positive',
          'test.assays.name' => 'MTB',
          'count' => 1
        }
      ])
    end

    it 'groups multiple elements by assays result and name' do
      index test: {
        assays: [
          { condition: 'mtb', result: :positive },
          { condition: 'rif', result: :negative }
        ]
      }
      index test: {
        assays: [
          { condition: 'mtb', result: :positive },
          { condition: 'rif', result: :positive }
        ]
      }
      index test: {
        assays: [
          { condition: 'mtb', result: :negative },
          { condition: 'rif', result: :positive }
        ]
      }

      response = query_tests(
        'test.assays.condition' => 'mtb',
        'group_by' => 'test.assays.result,test.assays.condition'
      ).sort_by do |test|
        test['test.assays.result'] + test['test.assays.condition']
      end

      expect(response).to eq([
        {
          'test.assays.result' => 'negative',
          'test.assays.condition' => 'mtb',
          'count' => 1
        },
        {
          'test.assays.result' => 'positive',
          'test.assays.condition' => 'mtb',
          'count' => 2
        }
      ])
    end

    it 'groups multiple elements by assays result and name filtering by two conditions' do
      index test: {
        assays: [
          { condition: 'mtb', result: :positive },
          { condition: 'rif', result: :negative },
          { condition: 'mtb', result: 'n/a' }
        ]
      }
      index test: {
        assays: [
          { condition: 'mtb', result: :positive },
          { condition: 'rif', result: :positive },
          { condition: 'mtb', result: 'n/a' }
        ]
      }
      index test: {
        assays: [
          { condition: 'mtb', result: :negative },
          { condition: 'rif', result: :positive },
          { condition: 'mtb', result: 'n/a' }
        ]
      }

      response = query_tests(
        'test.assays.condition' => 'mtb',
        'test.assays.result' => 'positive,negative',
        'group_by' => 'test.assays.result,test.assays.condition'
      ).sort_by do |test|
        test['test.assays.result'] + test['test.assays.condition']
      end

      expect(response).to eq([
        {
          'test.assays.result' => 'negative',
          'test.assays.condition' => 'mtb',
          'count' => 1
        },
        {
          'test.assays.result' => 'positive',
          'test.assays.condition' => 'mtb',
          'count' => 2
        }
      ])
    end

    it "groups by error code" do
      index test: {error_code: 1}
      index test: {error_code: 2}
      index test: {error_code: 2}
      index test: {error_code: 2}

      response = query_tests("group_by" => "test.error_code").sort_by do |test|
        test["test.error_code"]
      end

      expect(response).to eq([
        {"test.error_code" => 1, "count" => 1},
        {"test.error_code" => 2, "count" => 3}
      ])
    end

    it "returns 0 elements if no tests match the filter by name name" do
      index test: {assays:[name: "MTB", result: :positive]}
      index test: {assays:[name: "Flu", result: :negative]}

      assays = query('test.assays.result' => 'foo', "group_by" => "test.assays.result")

      expect(assays["tests"].length).to eq(0)
      expect(assays["total_count"]).to eq(0)

      assays = query('test.assays.result' => 'foo')

      expect(assays["tests"].length).to eq(0)
      expect(assays["total_count"]).to eq(0)
    end

    describe "by fields with option valid values" do
      skip "should include group for option with 0 assays" do
        index test: {assays:[result: :positive], type: "qc"}
        index test: {assays:[result: :positive], type: "qc"}

        response = query_tests(group_by:"test.type").sort_by do |test|
          test["test.type"]
        end

        expect(response).to eq([
          {"test.type"=>"qc", "count" => 2},
          {"test.type"=>"specimen", "count" => 0}
        ])
      end
    end
  end

  describe "Ordering" do
    it "should order by age" do
      index_with_test_result test: {assays:[result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index_with_test_result test: {assays:[result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}

      response = query_tests("order_by" => 'encounter.patient_age')

      expect(response[0]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[0]["encounter"]["patient_age"]["years"]).to eq(10)
      expect(response[1]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[1]["encounter"]["patient_age"]["years"]).to eq(20)
    end

    it "should order by age desc" do
      index_with_test_result test: {assays:[result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}
      index_with_test_result test: {assays:[result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}

      response = query_tests("order_by" => "-encounter.patient_age")

      expect(response[0]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[0]["encounter"]["patient_age"]["years"]).to eq(20)
      expect(response[1]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[1]["encounter"]["patient_age"]["years"]).to eq(10)
    end

    it "should order by age and gender" do
      index_with_test_result test: {assays:[result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}, patient: {gender: :male}
      index_with_test_result test: {assays:[result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}, patient: {gender: :male}
      index_with_test_result test: {assays:[result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}, patient: {gender: :female}
      index_with_test_result test: {assays:[result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}, patient: {gender: :female}

      response = query_tests("order_by" => "encounter.patient_age,patient.gender")

      expect(response[0]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[0]["encounter"]["patient_age"]["years"]).to eq(10)
      expect(response[0]["patient"]["gender"]).to eq("female")
      expect(response[1]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[1]["encounter"]["patient_age"]["years"]).to eq(10)
      expect(response[1]["patient"]["gender"]).to eq("male")
      expect(response[2]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[2]["encounter"]["patient_age"]["years"]).to eq(20)
      expect(response[2]["patient"]["gender"]).to eq("female")
      expect(response[3]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[3]["encounter"]["patient_age"]["years"]).to eq(20)
      expect(response[3]["patient"]["gender"]).to eq("male")
    end

    it "should order by age and gender desc" do
      index_with_test_result test: {assays:[result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}, patient: {gender: :male}
      index_with_test_result test: {assays:[result: :positive]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}, patient: {gender: :male}
      index_with_test_result test: {assays:[result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}, patient: {gender: :female}
      index_with_test_result test: {assays:[result: :negative]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}, patient: {gender: :female}

      response = query_tests("order_by" => "encounter.patient_age,-patient.gender")

      expect(response[0]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[0]["encounter"]["patient_age"]["years"]).to eq(10)
      expect(response[0]["patient"]["gender"]).to eq("male")
      expect(response[1]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[1]["encounter"]["patient_age"]["years"]).to eq(10)
      expect(response[1]["patient"]["gender"]).to eq("female")
      expect(response[2]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[2]["encounter"]["patient_age"]["years"]).to eq(20)
      expect(response[2]["patient"]["gender"]).to eq("male")
      expect(response[3]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[3]["encounter"]["patient_age"]["years"]).to eq(20)
      expect(response[3]["patient"]["gender"]).to eq("female")
    end

    it "orders a grouped result" do
      index test: {assays:[result: :positive], reported_time: time(2010, 1, 1)}
      index test: {assays:[result: :positive], reported_time: time(2010, 2, 2)}
      index test: {assays:[result: :positive], reported_time: time(2011, 1, 1)}
      index test: {assays:[result: :positive], reported_time: time(2011, 1, 2)}
      index test: {assays:[result: :positive], reported_time: time(2011, 2, 1)}

      response = query_tests("group_by" => "month(test.reported_time)", "order_by" => "test.reported_time")

      expect(response).to eq([
        {"test.reported_time"=>"2010-01", "count" => 1},
        {"test.reported_time"=>"2010-02", "count" => 1},
        {"test.reported_time"=>"2011-01", "count" => 2},
        {"test.reported_time"=>"2011-02", "count" => 1}
      ])

      response = query_tests("group_by" => "month(test.reported_time)", "order_by" => "-test.reported_time")

      expect(response).to eq([
        {"test.reported_time"=>"2011-02", "count" => 1},
        {"test.reported_time"=>"2011-01", "count" => 2},
        {"test.reported_time"=>"2010-02", "count" => 1},
        {"test.reported_time"=>"2010-01", "count" => 1}
      ])
    end
  end

  context "Location" do
    it "filters by location" do
      index test: {assays: [result: "negative"]}, location: {parents: [1, 2, 3]}
      index test: {assays: [result: "positive"]}, location: {parents: [1, 2, 4]}
      index test: {assays: [result: "positive with riff"]}, location: {parents: [1, 5]}

      expect_one_result "negative", 'location' => 3
      expect_one_result "positive", 'location' => 4

      response = query_tests('location' => 2).sort_by do |test|
        test["test"]["assays"].first["result"]
      end

      expect(response.size).to eq(2)
      expect(response[0]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[1]["test"]["assays"].first["result"]).to eq("positive")

      response = query_tests('location' => 1).sort_by do |test|
        test["test"]["assays"].first["result"]
      end

      expect(response.size).to eq(3)
      expect(response[0]["test"]["assays"].first["result"]).to eq("negative")
      expect(response[1]["test"]["assays"].first["result"]).to eq("positive")
      expect(response[2]["test"]["assays"].first["result"]).to eq("positive with riff")
    end

    it "groups by administrative level" do
      index test: {assays: [result: "negative"]}, location: {admin_levels: {admin_level_0: "1", admin_level_1: "2"}}
      index test: {assays: [result: "positive"]}, location: {admin_levels: {admin_level_0: "1", admin_level_1: "2"}}
      index test: {assays: [result: "positive with riff"]}, location: {admin_levels: {admin_level_0: "1", admin_level_1: "5"}}

      response = query_tests("group_by" => {'admin_level' => 1})
      expect(response).to eq([
        {"location"=>"2", "count" => 2},
        {"location"=>"5", "count" => 1}
      ])

      response = query_tests("group_by" => {'admin_level' => 0})

      expect(response).to eq([
        {"location"=>"1", "count" => 3}
      ])
    end

    context "with a second location field" do
      before(:all) do
        # add a new core field and regenerate the indexed fields with it.
        @extra_scope = Cdx::Scope.new('patient_location', 'fields' => {
          "id" => {},
          "parents" => {"searchable" => true},
          "admin_levels" => {"searchable" => true, "type" => 'dynamic'},
          "lat" => {},
          "lng" => {},
        })

        @extra_fields = @extra_scope.flatten.select(&:searchable?).map do |core_field|
          Cdx::Api::Elasticsearch::IndexedField.for(core_field, [
            {
              "name" => 'patient_location.parents',
              "filter_parameter_definition" => [{
                "name" => 'patient_location.id',
                type: 'match'
              }]
            },
            {
              "name" => 'patient_location.admin_levels',
              "group_parameter_definition" => [{
                "name" => 'patient_location.admin_level',
                "type" => 'location'
              }]
            }
          ],
          Cdx::Api::Elasticsearch::CdxDocumentFormat::TestResult.new
          )
        end

        Cdx::Fields.test.core_field_scopes.push @extra_scope
        Cdx::Fields.test.core_fields.concat @extra_scope.flatten

        Cdx::Fields.test.searchable_fields.concat @extra_fields

        # Delete the index and recreate it to make ES grab the new template
        Cdx::Api.client.indices.delete index: "cdx_test", ignore: 404
        Cdx::Api.initialize_template "cdx_tests_template_test"
      end

      after(:all) do
        Cdx::Fields.test.core_field_scopes.delete @extra_scope
        @extra_scope.flatten.each do |field|
          Cdx::Fields.test.core_fields.delete field
        end

        @extra_fields.each do |field|
          Cdx::Fields.test.searchable_fields.delete field
        end

        # Delete the index and recreate it to make ES grab the new template
        Cdx::Api.client.indices.delete index: "cdx_test", ignore: 404
        Cdx::Api.initialize_template "cdx_tests_template_test"
      end

      it "should allow searching by the new field" do
        index patient_location: {id: 1, parents: [1]}
        index patient_location: {id: 2, parents: [1,2]}
        index patient_location: {id: 3, parents: [3]}

        response = query_tests 'patient_location.id' => 1
        expect(response.count).to eq(2)

        response = query_tests 'patient_location.id' => 3
        expect(response.count).to eq(1)
      end

      it "should allow grouping by new field's admin level" do
        index patient_location: {admin_levels: {admin_level_0: "1"}}
        index patient_location: {admin_levels: {admin_level_0: "1", admin_level_1: "2"}}
        index patient_location: {admin_levels: {admin_level_0: "3" }}

        response = query_tests("group_by" => { 'patient_location.admin_level' => 0 })
        expect(response).to eq [{"patient_location" => "1", "count" => 2}, {"patient_location" => "3", "count" => 1}]
      end
    end
  end

  context "Count" do
    it "gets total count" do
      index test: {patient_age: Cdx::Field::DurationField.years(1)}
      index test: {patient_age: Cdx::Field::DurationField.years(1)}
      index test: {patient_age: Cdx::Field::DurationField.years(1)}

      assays = query('test.patient_age' => "1yo..")
      expect(assays["tests"].length).to eq(3)
      expect(assays["total_count"]).to eq(3)
    end

    it "gets total count when there are no results" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}

      assays = query('encounter.patient_age' => "2yo..")
      expect(assays["tests"].length).to eq(0)
      expect(assays["total_count"]).to eq(0)
    end

    it "gets total count when paginated" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}

      assays = query('encounter.patient_age' => "1yo..", "page_size" => 2)
      expect(assays["tests"].length).to eq(2)
      expect(assays["total_count"]).to eq(3)
    end

    it "gets total count when paginated with offset" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(2)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(3)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}

      assays = query("page_size" => 1, "offset" => 1, "order_by" => 'encounter.patient_age')

      tests = assays["tests"]
      expect(tests.length).to eq(1)
      expect(tests.first["encounter"]["patient_age"]["years"]).to eq(2)
      expect(assays["total_count"]).to eq(3)
    end

    it "can't group by duration fields without telling the clusters" do
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(1)}
      index_with_test_result encounter: {patient_age: Cdx::Field::DurationField.years(2)}

      expect { query("group_by" => 'encounter.patient_age') }.to raise_exception "Can't group by duration field without ranges"
    end
  end
end
