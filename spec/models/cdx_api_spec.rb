require 'spec_helper'

describe Cdx::Api do

  include_context "elasticsearch index"
  include_context "cdx api helpers"

  describe "Filter" do
    it "should check for new tests since a date" do
      index results: [result: :positive], start_time: time(2013, 1, 1)
      index results: [result: :negative], start_time: time(2013, 1, 2)

      response = query_tests(since: time(2013, 1, 2))

      expect(response.size).to eq(1)
      expect(response.first["results"].first["result"]).to eq("negative")

      response = query_tests(since: time(2013, 1, 1)).sort_by do |test|
        test["results"].first["result"]
      end

      expect(response.first["results"].first["result"]).to eq("negative")
      expect(response.last["results"].first["result"]).to eq("positive")

      expect(query_tests(since: time(2013, 1, 3))).to be_empty
    end

    it "should check for new tests since a date in a differen time zone" do
      Time.zone = ActiveSupport::TimeZone["Asia/Seoul"]

      index results: [result: :positive], start_time: 3.day.ago.at_noon.iso8601
      index results: [result: :negative], start_time: 1.day.ago.at_noon.iso8601

      response = query_tests(since: 2.day.ago.at_noon.iso8601)

      expect(response.size).to eq(1)
      expect(response.first["results"].first["result"]).to eq("negative")

      response = query_tests(since: 4.day.ago.at_noon.iso8601).sort_by do |test|
        test["results"].first["result"]
      end

      expect(response.first["results"].first["result"]).to eq("negative")
      expect(response.last["results"].first["result"]).to eq("positive")

      expect(query_tests(since: Date.current.at_noon.iso8601)).to be_empty
    end

    it "should asume current timezone if no one is provided" do
      Time.zone = ActiveSupport::TimeZone["Asia/Seoul"]

      index results: [result: :negative], start_time: Time.zone.local(2010, 10, 10, 01, 00, 30).iso8601

      response = query_tests(since: '2010-10-10T01:00:29')

      expect(response.size).to eq(1)
      expect(response.first["results"].first["result"]).to eq("negative")
    end

    it "should check for new tests util a date" do
      index results: [result: :positive], start_time: time(2013, 1, 1)
      index results: [result: :negative], start_time: time(2013, 1, 3)

      expect_one_result "positive", until: time(2013, 1, 2)
    end

    it "filters by created_at_since and created_at_until" do
      index results: [result: :positive], created_at: time(2013, 1, 1)
      index results: [result: :positive], created_at: time(2013, 1, 3)

      expect_one_result "positive", created_at_since: time(2013, 1, 2), created_at_until: time(2013, 1, 3)
    end

    [
      [:device, :device_uuid, ["dev1", "dev2", "dev3"]],
      [:laboratory, :laboratory_id, [1, 2, 3]],
      [:institution, :institution_id, [1, 2, 3]],
      [:gender, :gender, ["male", "female", "unknown"]],
      [:assay_name, :assay_name, ["GX4001", "GX1234", "GX9999"]],
      [:age, :age, [10, 15, 20]],
      [:uuid, :uuid, ["1234", "5678", "9012"]],
    ].each do |query_name, index_name, values|
      it "should filter by #{query_name}" do
        index results: [result: :positive], index_name => values[0]
        index results: [result: :negative], index_name => values[1]

        expect_one_result "positive", query_name => values[0]
        expect_one_result "negative", query_name => values[1]
        expect_no_results query_name => values[2]
      end
    end

    it "filters by system_user" do
      index system_user: "jdoe"
      index system_user: "mmajor"

      expect_one_result_with_field "system_user", "jdoe", system_user: "jdoe"
      expect_one_result_with_field "system_user", "mmajor", system_user: "mmajor"
      expect_no_results system_user: "ffoo"
    end

    it "filters by min age" do
      index results: [result: :positive], age: 10
      index results: [result: :negative], age: 20

      expect_one_result "negative", min_age: 15
      expect_one_result "negative", min_age: 20
      expect_no_results min_age: 21
    end

    it "filters by max age" do
      index results: [result: :positive], age: 10
      index results: [result: :negative], age: 20

      expect_one_result "positive", max_age: 15
      expect_one_result "positive", max_age: 10
      expect_no_results max_age: 9
    end

    it "filters by result" do
      index results:[condition: "MTB", result: :positive], age: 10
      index results:[condition: "Flu", result: :negative], age: 20

      expect_one_result_with_field "age", 10, result: :positive
      expect_one_result_with_field "age", 20, result: :negative
    end

    it "filters by a partial match" do
      index results:[result: :positive], assay_name: "GX4001"
      index results:[result: :negative], assay_name: "GX1234"

      expect_one_result "negative", assay_name: "GX1*"
      expect_one_result "positive", assay_name: "GX4*"
      expect_no_results assay_name: "GX5*"
    end

    it "filters by condition name" do
      index results:[condition: "MTB", result: :positive]
      index results:[condition: "Flu", result: :negative]

      expect_one_result "positive", condition: "MTB"
      expect_one_result "negative", condition: "Flu"
      expect_no_results condition: "Qux"
    end

    it "filters by result, age and condition" do
      index results:[condition: "MTB", result: :positive], age: 20
      index results:[condition: "MTB", result: :negative], age: 20
      index results:[condition: "Flu", result: :negative], age: 20

      expect_one_result "negative", result: :negative, age: 20, condition: "Flu"
    end

    it "filters by test type" do
      index results:[condition: "MTB", result: :positive], test_type: :qc
      index results:[condition: "MTB", result: :negative], test_type: :specimen

      expect_one_result "negative", test_type: :specimen
    end

    it "filters by error code, one result expected" do
      index error_code: 1
      index error_code: 2

      expect_one_result_with_field "error_code", 1, error_code: 1
      expect_no_results error_code: 3
    end



    describe "Multi" do
      it "filters by multiple genders with array" do
        index age: 1, gender: "male"
        index age: 2, gender: "female"
        index age: 3, gender: "unknown"

        response = query_tests(gender: ["male", "female"]).sort_by do |test|
          test["age"]
        end

        expect(response).to eq([
          {"age" => 1, "gender" => "male"},
          {"age" => 2, "gender" => "female"},
        ])
      end

      it "filters by multiple genders with comma" do
        index age: 1, gender: "male"
        index age: 2, gender: "female"
        index age: 3, gender: "unknown"

        response = query_tests(gender: "male,female").sort_by do |test|
          test["age"]
        end

        expect(response).to eq([
          {"age" => 1, "gender" => "male"},
          {"age" => 2, "gender" => "female"},
        ])
      end

      it "filters by multiple test types with array" do
        index age: 1, test_type: "one"
        index age: 2, test_type: "two"
        index age: 3, test_type: "three"

        response = query_tests(test_type: ["one", "two"]).sort_by do |test|
          test["test_type"]
        end

        expect(response).to eq([
          {"age" => 1, "test_type" => "one"},
          {"age" => 2, "test_type" => "two"},
        ])
      end

      it "filters by multiple test types with comma" do
        index age: 1, test_type: "one"
        index age: 2, test_type: "two"
        index age: 3, test_type: "three"

        response = query_tests(test_type: "one,two").sort_by do |test|
          test["test_type"]
        end

        expect(response).to eq([
          {"age" => 1, "test_type" => "one"},
          {"age" => 2, "test_type" => "two"},
        ])
      end

      it "filters by null value" do
        index results:[result: :positive], age: 10
        index results:[condition: "Flu", result: :negative], age: 20
        index results:[condition: "MTB", result: :negative], age: 30

        expect_one_result "positive", condition: 'null'

        response = query_tests(condition: "null,MTB").sort_by do |test|
          test["age"]
        end

        expect(response).to eq([
          {"age" => 10, "results" => ["result" => "positive"]},
          {"age" => 30, "results" => ["condition" => "MTB", "result" => "negative"]}
        ])
      end

      it "filters by not(null) value" do
        index results:[result: :positive], age: 10
        index results:[condition: "Flu", result: :negative], age: 20
        index results:[condition: "MTB", result: :negative], age: 30

        response = query_tests(condition: "not(null)").sort_by do |test|
          test["age"]
        end

        expect(response).to eq([
          {"age" => 20, "results" => ["condition" => "Flu", "result" => "negative"]},
          {"age" => 30, "results" => ["condition" => "MTB", "result" => "negative"]}
        ])
      end
    end
  end

  describe "Grouping" do
    it "groups by gender" do
      index results:[result: :positive], gender: :male
      index results:[result: :negative], gender: :male
      index results:[result: :negative], gender: :female

      response = query_tests(group_by: :gender).sort_by do |test|
        test["gender"]
      end

      expect(response).to eq([
        {"gender"=>"female", count: 1},
        {"gender"=>"male", count: 2}
      ])
    end

    it "groups by gender and assay_name" do
      index results:[result: :positive], gender: :male, assay_name: "a"
      index results:[result: :positive], gender: :male, assay_name: "a"
      index results:[result: :positive], gender: :male, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "a"
      index results:[result: :negative], gender: :female, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "b"

      response = query_tests(group_by: "gender,assay_name").sort_by do |test|
        test["gender"] + test["assay_name"]
      end

      expect(response).to eq([
        {"gender"=>"female", "assay_name" => "a", count: 1},
        {"gender"=>"female", "assay_name" => "b", count: 2},
        {"gender"=>"male", "assay_name" => "a", count: 2},
        {"gender"=>"male", "assay_name" => "b", count: 1}
      ])
    end

    it "groups by test type" do
      index results:[result: :positive], test_type: "qc"
      index results:[result: :positive], test_type: "specimen"
      index results:[result: :positive], test_type: "qc"

      response = query_tests(group_by:"test_type").sort_by do |test|
        test["test_type"]
      end

      expect(response).to eq([
        {"test_type"=>"qc", count: 2},
        {"test_type"=>"specimen", count: 1},
      ])
    end

    it "groups by gender, assay_name and result" do
      index results:[result: :positive], gender: :male, assay_name: "a"
      index results:[result: :negative], gender: :male, assay_name: "a"
      index results:[result: :positive], gender: :male, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "a"
      index results:[result: :negative], gender: :female, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "b"

      response = query_tests(group_by: "gender,assay_name,result").sort_by do |test|
        test["gender"] + test["result"] + test["assay_name"]
      end

      expect(response).to eq([
        {"gender"=>"female", "result" => "negative", "assay_name" => "a", count: 1},
        {"gender"=>"female", "result" => "negative", "assay_name" => "b", count: 2},
        {"gender"=>"male", "result" => "negative", "assay_name" => "a", count: 1},
        {"gender"=>"male", "result" => "positive", "assay_name" => "a", count: 1},
        {"gender"=>"male", "result" => "positive", "assay_name" => "b", count: 1}
      ])
    end

    it "groups by gender, assay_name and result in a different order" do
      index results:[result: :positive], gender: :male, assay_name: "a"
      index results:[result: :negative], gender: :male, assay_name: "a"
      index results:[result: :positive], gender: :male, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "a"
      index results:[result: :negative], gender: :female, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "b"

      response = query_tests(group_by: "result,gender,assay_name").sort_by do |test|
        test["gender"] + test["result"] + test["assay_name"]
      end

      expect(response).to eq([
        {"gender"=>"female", "result" => "negative", "assay_name" => "a", count: 1},
        {"gender"=>"female", "result" => "negative", "assay_name" => "b", count: 2},
        {"gender"=>"male", "result" => "negative", "assay_name" => "a", count: 1},
        {"gender"=>"male", "result" => "positive", "assay_name" => "a", count: 1},
        {"gender"=>"male", "result" => "positive", "assay_name" => "b", count: 1}
      ])
    end

    it "groups by system user" do
      index system_user: "jdoe"
      index system_user: "jdoe"
      index system_user: "mmajor"
      index system_user: "mmajor"

      response = query_tests(group_by: "system_user").sort_by do |test|
        test["system_user"]
      end

      expect(response).to eq([
        {"system_user"=>"jdoe", count:2},
        {"system_user"=>"mmajor", count:2},
      ])
    end

    it "raises exception when interval is not supported" do
      index results:[result: :positive], created_at: time(2010, 1, 1)
      index results:[result: :positive], created_at: time(2010, 1, 2)
      index results:[result: :positive], created_at: time(2011, 1, 1)

      expect {
        query_tests(group_by: "foo(created_at)")
      }.to raise_error
    end

    it "groups by year(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 1)
      index results:[result: :positive], created_at: time(2010, 1, 2)
      index results:[result: :positive], created_at: time(2011, 1, 1)

      response = query_tests(group_by: "year(created_at)").sort_by do |test|
        test["created_at"]
      end

      expect(response).to eq([
        {"created_at"=>"2010", count: 2},
        {"created_at"=>"2011", count: 1}
      ])
    end

    it "groups by month(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 1)
      index results:[result: :positive], created_at: time(2010, 2, 2)
      index results:[result: :positive], created_at: time(2011, 1, 1)
      index results:[result: :positive], created_at: time(2011, 1, 2)
      index results:[result: :positive], created_at: time(2011, 2, 1)

      response = query_tests(group_by: "month(created_at)").sort_by do |test|
        test["created_at"]
      end

      expect(response).to eq([
        {"created_at"=>"2010-01", count: 1},
        {"created_at"=>"2010-02", count: 1},
        {"created_at"=>"2011-01", count: 2},
        {"created_at"=>"2011-02", count: 1}
      ])
    end

    it "groups by week(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 5)
      index results:[result: :positive], created_at: time(2010, 1, 6)
      index results:[result: :positive], created_at: time(2010, 1, 12)
      index results:[result: :positive], created_at: time(2010, 1, 13)
      index results:[result: :positive], created_at: time(2010, 6, 13)

      response = query_tests(group_by: "week(created_at)").sort_by do |test|
        test["created_at"]
      end

      expect(response).to eq([
        {"created_at"=>"2010-W01", count: 3},
        {"created_at"=>"2010-W02", count: 2},
        {"created_at"=>"2010-W23", count: 1},
      ])
    end

    it "groups by week(date) and uses weekyear" do
      index created_at: time(2012, 12, 31)

      response = query_tests(group_by: "week(created_at)")

      expect(response).to eq([
        {"created_at"=>"2013-W01", count: 1},
      ])
    end

    it "groups by day(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 5)

      response = query_tests(group_by: "day(created_at)").sort_by do |test|
        test["created_at"]
      end

      expect(response).to eq([
        {"created_at"=>"2010-01-04", count: 3},
        {"created_at"=>"2010-01-05", count: 1}
      ])
    end

    it "groups by day(date) and result" do
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :negative], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 5)

      response = query_tests(group_by: "day(created_at),result").sort_by do |test|
        test["created_at"] + test["result"]
      end

      expect(response).to eq([
        {"created_at"=>"2010-01-04", "result" => "negative", count: 1},
        {"created_at"=>"2010-01-04", "result" => "positive", count: 2},
        {"created_at"=>"2010-01-05", "result" => "positive", count: 1}
      ])
    end

    it "groups by age ranges" do
      index age: 9
      index age: 10
      index age: 11
      index age: 12
      index age: 13
      index age: 20
      index age: 21

      response = query_tests(group_by: [{"age" => [[nil, 10], [15, 120], [10, 15]]}]).sort_by do |test|
        test["age"].compact
      end

      expect(response).to eq([
        {"age"=>[nil, 10], count: 1},
        {"age"=>[10, 15], count: 4},
        {"age"=>[15, 120], count: 2}
      ])
    end

    it "groups by age ranges using hashes" do
      index age: 9
      index age: 10
      index age: 11
      index age: 12
      index age: 13
      index age: 20
      index age: 21

      response = query_tests(group_by: [{"age" => [{to: 10}, [10, 15], {from: 16, to: 21}, [21]]}]).sort_by do |test|
        test["age"].compact
      end

      expect(response).to eq([
        {"age"=>[nil, 10], count: 1},
        {"age"=>[10, 15], count: 4},
        {"age"=>[16, 21], count: 1},
        {"age"=>[21, nil], count: 1}
      ])
    end

    it "groups by age ranges without the array" do
      index age: 9
      index age: 10
      index age: 11
      index age: 12
      index age: 13
      index age: 20
      index age: 21

      response = query_tests(group_by: {"age" => [[0, 10], [15, 120], [10, 15]]}).sort_by do |test|
        test["age"]
      end

      expect(response).to eq([
        {"age"=>[0, 10], count: 1},
        {"age"=>[10, 15], count: 4},
        {"age"=>[15, 120], count: 2}
      ])
    end

    it "groups by results result" do
      index results:[
        {condition: "MTB", result: :positive},
        {condition: "Flu", result: :negative},
      ]

      response = query_tests(group_by: :result).sort_by do |test|
        test["result"]
      end

      expect(response).to eq([
        {"result"=>"negative", count: 1},
        {"result"=>"positive", count: 1}
      ])
    end

    it "groups by results result and condition" do
      index results:[
        {condition: "MTB", result: :positive},
        {condition: "Flu", result: :negative},
      ]

      response = query_tests(group_by: "result,condition").sort_by do |test|
        test["result"] + test["condition"]
      end

      expect(response).to eq([
        {"result"=>"negative", "condition" => "Flu", count: 1},
        {"result"=>"positive", "condition" => "MTB", count: 1}
      ])
    end

    it "groups by error code" do
      index error_code: 1
      index error_code: 2
      index error_code: 2
      index error_code: 2

      response = query_tests(group_by: "error_code").sort_by do |test|
        test["error_code"]
      end

      expect(response).to eq([
        {"error_code" => 1, count: 1},
        {"error_code" => 2, count: 3}
      ])
    end

    it "returns 0 elements if no tests match the filter by condition name" do
      index results:[condition: "MTB", result: :positive]
      index results:[condition: "Flu", result: :negative]

      results = query(result: 'foo', group_by: "result")

      expect(results["tests"].length).to eq(0)
      expect(results["total_count"]).to eq(0)

      results = query(result: 'foo')

      expect(results["tests"].length).to eq(0)
      expect(results["total_count"]).to eq(0)
    end

    describe "by fields with option valid values" do
      pending "should include group for option with 0 results" do
        index results:[result: :positive], test_type: "qc"
        index results:[result: :positive], test_type: "qc"

        response = query_tests(group_by:"test_type").sort_by do |test|
          test["test_type"]
        end

        expect(response).to eq([
          {"test_type"=>"qc", count: 2},
          {"test_type"=>"specimen", count: 0}
        ])
      end
    end
  end

  describe "Ordering" do
    it "should order by age" do
      index results:[result: :positive], age: 20
      index results:[result: :negative], age: 10

      response = query_tests(order_by: :age)

      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[0]["age"]).to eq(10)
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[1]["age"]).to eq(20)
    end

    it "should order by age desc" do
      index results:[result: :positive], age: 20
      index results:[result: :negative], age: 10

      response = query_tests(order_by: "-age")

      expect(response[0]["results"].first["result"]).to eq("positive")
      expect(response[0]["age"]).to eq(20)
      expect(response[1]["results"].first["result"]).to eq("negative")
      expect(response[1]["age"]).to eq(10)
    end

    it "should order by age and gender" do
      index results:[result: :positive], age: 20, gender: :male
      index results:[result: :positive], age: 10, gender: :male
      index results:[result: :negative], age: 20, gender: :female
      index results:[result: :negative], age: 10, gender: :female

      response = query_tests(order_by: "age,gender")

      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[0]["age"]).to eq(10)
      expect(response[0]["gender"]).to eq("female")
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[1]["age"]).to eq(10)
      expect(response[1]["gender"]).to eq("male")
      expect(response[2]["results"].first["result"]).to eq("negative")
      expect(response[2]["age"]).to eq(20)
      expect(response[2]["gender"]).to eq("female")
      expect(response[3]["results"].first["result"]).to eq("positive")
      expect(response[3]["age"]).to eq(20)
      expect(response[3]["gender"]).to eq("male")
    end

    it "should order by age and gender desc" do
      index results:[result: :positive], age: 20, gender: :male
      index results:[result: :positive], age: 10, gender: :male
      index results:[result: :negative], age: 20, gender: :female
      index results:[result: :negative], age: 10, gender: :female

      response = query_tests(order_by: "age,-gender")

      expect(response[0]["results"].first["result"]).to eq("positive")
      expect(response[0]["age"]).to eq(10)
      expect(response[0]["gender"]).to eq("male")
      expect(response[1]["results"].first["result"]).to eq("negative")
      expect(response[1]["age"]).to eq(10)
      expect(response[1]["gender"]).to eq("female")
      expect(response[2]["results"].first["result"]).to eq("positive")
      expect(response[2]["age"]).to eq(20)
      expect(response[2]["gender"]).to eq("male")
      expect(response[3]["results"].first["result"]).to eq("negative")
      expect(response[3]["age"]).to eq(20)
      expect(response[3]["gender"]).to eq("female")
    end

    it "orders a grouped result" do
      index results:[result: :positive], created_at: time(2010, 1, 1)
      index results:[result: :positive], created_at: time(2010, 2, 2)
      index results:[result: :positive], created_at: time(2011, 1, 1)
      index results:[result: :positive], created_at: time(2011, 1, 2)
      index results:[result: :positive], created_at: time(2011, 2, 1)

      response = query_tests(group_by: "month(created_at)", order_by: "created_at")

      expect(response).to eq([
        {"created_at"=>"2010-01", count: 1},
        {"created_at"=>"2010-02", count: 1},
        {"created_at"=>"2011-01", count: 2},
        {"created_at"=>"2011-02", count: 1}
      ])

      response = query_tests(group_by: "month(created_at)", order_by: "-created_at")

      expect(response).to eq([
        {"created_at"=>"2011-02", count: 1},
        {"created_at"=>"2011-01", count: 2},
        {"created_at"=>"2010-02", count: 1},
        {"created_at"=>"2010-01", count: 1}
      ])
    end
  end

  context "Location" do
    it "filters by location" do
      index results: [result: "negative"], parent_locations: [1, 2, 3]
      index results: [result: "positive"], parent_locations: [1, 2, 4]
      index results: [result: "positive with riff"], parent_locations: [1, 5]

      expect_one_result "negative", location: 3
      expect_one_result "positive", location: 4

      response = query_tests(location: 2).sort_by do |test|
        test["results"].first["result"]
      end

      expect(response.size).to eq(2)
      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[1]["results"].first["result"]).to eq("positive")

      response = query_tests(location: 1).sort_by do |test|
        test["results"].first["result"]
      end

      expect(response.size).to eq(3)
      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[2]["results"].first["result"]).to eq("positive with riff")
    end

    it "groups by administrative level" do
      index results: [result: "negative"], location: { admin_level_0: 1, admin_level_1: 2 }
      index results: [result: "positive"], location: { admin_level_0: 1, admin_level_1: 2 }
      index results: [result: "positive with riff"], location: { admin_level_0: 1, admin_level_1: 5 }

      response = query_tests(group_by: {admin_level: 1})
      expect(response).to eq([
        {"location"=>"2", count: 2},
        {"location"=>"5", count: 1}
      ])

      response = query_tests(group_by: {admin_level: 0})

      expect(response).to eq([
        {"location"=>"1", count: 3}
      ])
    end

    context "with a second location field" do
      before(:all) do
        @extra_field = Cdx::Api::Elasticsearch::IndexedField.new({ name: 'patient_loc', type: 'location' }, Cdx::Api.config.document_format)
        Cdx::Api.searchable_fields.push @extra_field

        # Delete the index and recreate it to make ES grab the new template
        Cdx::Api.client.indices.delete index: "cdx_tests" rescue nil
        Cdx::Api.initialize_default_template "cdx_tests_template"
      end

      after(:all) do
        Cdx::Api.searchable_fields.delete @extra_field

        # Delete the index and recreate it to make ES grab the new template
        Cdx::Api.client.indices.delete index: "cdx_tests" rescue nil
        Cdx::Api.initialize_default_template "cdx_tests_template"
      end

      it "should allow searching by the new field" do
        index patient_loc_id: 1, parent_patient_locs: [1]
        index patient_loc_id: 2, parent_patient_locs: [1,2]
        index patient_loc_id: 3, parent_patient_locs: [3]

        response = query_tests patient_loc: 1
        expect(response.count).to eq(2)

        response = query_tests patient_loc: 3
        expect(response.count).to eq(1)
      end

      it "should allow grouping by new field's admin level" do
        index patient_loc: { admin_level_0: 1 }
        index patient_loc: { admin_level_0: 1, admin_level_1: 2}
        index patient_loc: { admin_level_0: 3 }

        response = query_tests(group_by: { patient_loc_admin_level: 0 })
        expect(response).to eq [{"patient_loc" => "1", :count => 2}, {"patient_loc" => "3", :count => 1}]
      end
    end
  end

  context "Count" do
    it "gets total count" do
      index age: 1
      index age: 1
      index age: 1

      results = query(age: 1)
      expect(results["tests"].length).to eq(3)
      expect(results["total_count"]).to eq(3)
    end

    it "gets total count when paginated" do
      index age: 1
      index age: 1
      index age: 1

      results = query(age: 1, page_size: 2)
      expect(results["tests"].length).to eq(2)
      expect(results["total_count"]).to eq(3)
    end

    it "gets total count when paginated with offset" do
      index age: 1
      index age: 2
      index age: 3

      results = query(page_size: 1, offset: 1, order_by: 'age')

      tests = results["tests"]
      expect(tests.length).to eq(1)
      expect(tests.first["age"]).to eq(2)
      expect(results["total_count"]).to eq(3)
    end

    it "gets total count when grouping" do
      index age: 1
      index age: 1
      index age: 2

      results = query(group_by: :age)
      expect(results["total_count"]).to eq(3)
    end
  end
end
