require 'spec_helper'

describe Cdx::Api do
  def index(body)
    Cdx::Api.client.index index: "cdx_events", type: "event", body: body, refresh: true
  end

  def query_events(query)
    query(query)["events"]
  end

  def query(query)
    Cdx::Api::Elasticsearch::Query.new(query.with_indifferent_access).execute
  end

  def time(year, month, day, hour = 12, minute = 0, second = 0)
    Time.local(year, month, day, hour, minute, second).iso8601
  end

  def expect_one_result(result, query)
    response = query_events(query)

    expect(response.size).to eq(1)
    expect(response.first["results"].first["result"]).to eq(result)
  end

  def expect_one_result_with_field(key, value, query)
    response = query_events(query)

    expect(response.size).to eq(1)
    expect(response.first[key]).to eq(value)
  end

  def expect_one(query)
    response = query_events(query)

    expect(response.size).to eq(1)
    yield response.first
  end

  def expect_no_results(query)
    response = query_events(query)

    expect(response).to be_empty
  end

  before(:each) do
    Cdx::Api.client.delete_by_query index: "cdx_events", body: { query: { match_all: {} } } rescue nil
  end

  describe "Filter" do
    it "should check for new events since a date" do
      index results: [result: :positive], created_at: time(2013, 1, 1)
      index results: [result: :negative], created_at: time(2013, 1, 2)

      response = query_events(since: time(2013, 1, 2))

      expect(response.size).to eq(1)
      expect(response.first["results"].first["result"]).to eq("negative")

      response = query_events(since: time(2013, 1, 1))

      expect(response.first["results"].first["result"]).to eq("positive")
      expect(response.last["results"].first["result"]).to eq("negative")

      expect(query_events(since: time(2013, 1, 3))).to be_empty
    end

    it "should check for new events since a date in a differen time zone" do
      Time.zone = ActiveSupport::TimeZone["Asia/Seoul"]

      index results: [result: :positive], created_at: 3.day.ago.at_noon.iso8601
      index results: [result: :negative], created_at: 1.day.ago.at_noon.iso8601

      response = query_events(since: 2.day.ago.at_noon.iso8601)

      expect(response.size).to eq(1)
      expect(response.first["results"].first["result"]).to eq("negative")

      response = query_events(since: 4.day.ago.at_noon.iso8601)

      expect(response.first["results"].first["result"]).to eq("positive")
      expect(response.last["results"].first["result"]).to eq("negative")

      expect(query_events(since: Date.current.at_noon.iso8601)).to be_empty
    end

    it "should check for new events util a date" do
      index results: [result: :positive], created_at: time(2013, 1, 1)
      index results: [result: :negative], created_at: time(2013, 1, 3)

      expect_one_result "positive", until: time(2013, 1, 2)
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

        response = query_events(gender: ["male", "female"]).sort_by do |event|
          event["age"]
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

        response = query_events(gender: "male,female").sort_by do |event|
          event["age"]
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

        response = query_events(test_type: ["one", "two"]).sort_by do |event|
          event["test_type"]
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

        response = query_events(test_type: "one,two").sort_by do |event|
          event["test_type"]
        end

        expect(response).to eq([
          {"age" => 1, "test_type" => "one"},
          {"age" => 2, "test_type" => "two"},
        ])
      end
    end
  end

  describe "Grouping" do
    it "groups by gender" do
      index results:[result: :positive], gender: :male
      index results:[result: :negative], gender: :male
      index results:[result: :negative], gender: :female

      response = query_events(group_by: :gender).sort_by do |event|
        event["gender"]
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

      response = query_events(group_by: "gender,assay_name").sort_by do |event|
        event["gender"] + event["assay_name"]
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

      response = query_events(group_by:"test_type").sort_by do |event|
        event["test_type"]
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

      response = query_events(group_by: "gender,assay_name,result").sort_by do |event|
        event["gender"] + event["result"] + event["assay_name"]
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

      response = query_events(group_by: "result,gender,assay_name").sort_by do |event|
        event["gender"] + event["result"] + event["assay_name"]
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

      response = query_events(group_by: "system_user").sort_by do |event|
        event["system_user"]
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
        query_events(group_by: "foo(created_at)")
      }.to raise_error
    end

    it "groups by year(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 1)
      index results:[result: :positive], created_at: time(2010, 1, 2)
      index results:[result: :positive], created_at: time(2011, 1, 1)

      response = query_events(group_by: "year(created_at)").sort_by do |event|
        event["created_at"]
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

      response = query_events(group_by: "month(created_at)").sort_by do |event|
        event["created_at"]
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

      response = query_events(group_by: "week(created_at)").sort_by do |event|
        event["created_at"]
      end

      expect(response).to eq([
        {"created_at"=>"2010-W1", count: 3},
        {"created_at"=>"2010-W2", count: 2}
      ])
    end

    it "groups by day(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 4)
      index results:[result: :positive], created_at: time(2010, 1, 5)

      response = query_events(group_by: "day(created_at)").sort_by do |event|
        event["created_at"]
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

      response = query_events(group_by: "day(created_at),result").sort_by do |event|
        event["created_at"] + event["result"]
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

      response = query_events(group_by: [{"age" => [[nil, 10], [15, 120], [10, 15]]}]).sort_by do |event|
        event["age"].compact
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

      response = query_events(group_by: [{"age" => [{to: 10}, [10, 15], {from: 16, to: 21}, [21]]}]).sort_by do |event|
        event["age"].compact
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

      response = query_events(group_by: {"age" => [[0, 10], [15, 120], [10, 15]]}).sort_by do |event|
        event["age"]
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

      response = query_events(group_by: :result).sort_by do |event|
        event["result"]
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

      response = query_events(group_by: "result,condition").sort_by do |event|
        event["result"] + event["condition"]
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

      response = query_events(group_by: "error_code").sort_by do |event|
        event["error_code"]
      end

      expect(response).to eq([
        {"error_code" => 1, count: 1},
        {"error_code" => 2, count: 3}
      ])
    end


    describe "by fields with option valid values" do
      pending "should include group for option with 0 results" do
        index results:[result: :positive], test_type: "qc"
        index results:[result: :positive], test_type: "qc"

        response = query_events(group_by:"test_type").sort_by do |event|
          event["test_type"]
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

      response = query_events(order_by: :age)

      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[0]["age"]).to eq(10)
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[1]["age"]).to eq(20)
    end

    it "should order by age desc" do
      index results:[result: :positive], age: 20
      index results:[result: :negative], age: 10

      response = query_events(order_by: "-age")

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

      response = query_events(order_by: "age,gender")

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

      response = query_events(order_by: "age,-gender")

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
  end

  context "Location" do
    it "filters by location" do
      index results: [result: "negative"], parent_locations: [1, 2, 3]
      index results: [result: "positive"], parent_locations: [1, 2, 4]
      index results: [result: "positive with riff"], parent_locations: [1, 5]

      expect_one_result "negative", location: 3
      expect_one_result "positive", location: 4

      response = query_events(location: 2).sort_by do |event|
        event["results"].first["result"]
      end

      expect(response.size).to eq(2)
      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[1]["results"].first["result"]).to eq("positive")

      response = query_events(location: 1).sort_by do |event|
        event["results"].first["result"]
      end

      expect(response.size).to eq(3)
      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[2]["results"].first["result"]).to eq("positive with riff")
    end

    it "groups by administrative level" do
      allow_any_instance_of(KindGroupingDetail).to receive(:target_grouping_values) do |obj|
        case obj.value
        when 0
          [1]
        when 1
          [2, 5]
        else
          fail
        end
      end

      index results: [result: "negative"], parent_locations: [1, 2, 3]
      index results: [result: "positive"], parent_locations: [1, 2, 4]
      index results: [result: "positive with riff"], parent_locations: [1, 5]

      response = query_events(group_by: {admin_level: 1})
      expect(response).to eq([
        {"location"=>2, count: 2},
        {"location"=>5, count: 1}
      ])

      response = query_events(group_by: {admin_level: 0})

      expect(response).to eq([
        {"location"=>1, count: 3}
      ])
    end
  end

  context "Count" do
    it "gets total count" do
      index age: 1
      index age: 1
      index age: 1

      results = query(age: 1)
      expect(results["events"].length).to eq(3)
      expect(results["total_count"]).to eq(3)
    end

    it "gets total count when paginated" do
      index age: 1
      index age: 1
      index age: 1

      results = query(age: 1, page_size: 2)
      expect(results["events"].length).to eq(2)
      expect(results["total_count"]).to eq(3)
    end

    it "gets total count when paginated with offset" do
      index age: 1
      index age: 2
      index age: 3

      results = query(page_size: 1, offset: 1, order_by: 'age')

      events = results["events"]
      expect(events.length).to eq(1)
      expect(events.first["age"]).to eq(2)
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
