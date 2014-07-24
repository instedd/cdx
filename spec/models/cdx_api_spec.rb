require 'spec_helper'

describe Cdx::Api do
  def index(body)
    Cdx::Api.client.index index: "cdx_events", type: "event", body: body, refresh: true
  end

  def query(query)
    Cdx::Api::Elasticsearch::Query.new(query.with_indifferent_access).execute
  end

  def time(year, month, day, hour = 12, minute = 0, second = 0)
    Time.utc(year, month, day, hour, minute, second).iso8601
  end

  def expect_one_result(result, query)
    response = query(query)

    expect(response.size).to eq(1)
    expect(response.first["results"].first["result"]).to eq(result)
  end

  def expect_one_result_with_field(key, value, query)
    response = query(query)

    expect(response.size).to eq(1)
    expect(response.first[key]).to eq(value)
  end

  def expect_one(query)
    response = query(query)

    expect(response.size).to eq(1)
    yield response.first
  end

  def expect_no_results(query)
    response = query(query)

    expect(response).to be_empty
  end

  before(:each) do
    Cdx::Api.client.delete_by_query index: "cdx_events", body: { query: { match_all: {} } } rescue nil
  end

  describe "Filter" do
    it "should check for new events since a date" do
      index results: [result: :positive], created_at: time(2013, 1, 1)
      index results: [result: :negative], created_at: time(2013, 1, 2)

      response = query(since: time(2013, 1, 2))

      expect(response.size).to eq(1)
      expect(response.first["results"].first["result"]).to eq("negative")

      response = query(since: time(2013, 1, 1))

      expect(response.first["results"].first["result"]).to eq("positive")
      expect(response.last["results"].first["result"]).to eq("negative")

      expect(query(since: time(2013, 1, 3))).to be_empty
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
  end

  describe "Grouping" do
    it "groups by gender" do
      index results:[result: :positive], gender: :male
      index results:[result: :negative], gender: :male
      index results:[result: :negative], gender: :female

      response = query(group_by: :gender).sort_by do |event|
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

      response = query(group_by: "gender,assay_name").sort_by do |event|
        event["gender"] + event["assay_name"]
      end

      expect(response).to eq([
        {"gender"=>"female", "assay_name" => "a", count: 1},
        {"gender"=>"female", "assay_name" => "b", count: 2},
        {"gender"=>"male", "assay_name" => "a", count: 2},
        {"gender"=>"male", "assay_name" => "b", count: 1}
      ])
    end

    it "groups by gender, assay_name and result" do
      index results:[result: :positive], gender: :male, assay_name: "a"
      index results:[result: :negative], gender: :male, assay_name: "a"
      index results:[result: :positive], gender: :male, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "a"
      index results:[result: :negative], gender: :female, assay_name: "b"
      index results:[result: :negative], gender: :female, assay_name: "b"

      response = query(group_by: "gender,assay_name,result").sort_by do |event|
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

      response = query(group_by: "result,gender,assay_name").sort_by do |event|
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

    it "groups by year(date)" do
      index results:[result: :positive], created_at: time(2010, 1, 1)
      index results:[result: :positive], created_at: time(2010, 1, 2)
      index results:[result: :positive], created_at: time(2011, 1, 1)

      response = query(group_by: "year(created_at)").sort_by do |event|
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

      response = query(group_by: "month(created_at)").sort_by do |event|
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

      response = query(group_by: "week(created_at)").sort_by do |event|
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

      response = query(group_by: "day(created_at)").sort_by do |event|
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

      response = query(group_by: "day(created_at),result").sort_by do |event|
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

      response = query(group_by: [{"age" => [[nil, 10], [15, 120], [10, 15]]}]).sort_by do |event|
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

      response = query(group_by: [{"age" => [{to: 10}, [10, 15], {from: 16, to: 21}, [21]]}]).sort_by do |event|
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

      response = query(group_by: {"age" => [[0, 10], [15, 120], [10, 15]]}).sort_by do |event|
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

      response = query(group_by: :result).sort_by do |event|
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

      response = query(group_by: "result,condition").sort_by do |event|
        event["result"] + event["condition"]
      end

      expect(response).to eq([
        {"result"=>"negative", "condition" => "Flu", count: 1},
        {"result"=>"positive", "condition" => "MTB", count: 1}
      ])
    end
  end

  describe "Ordering" do
    it "should order by age" do
      index results:[result: :positive], age: 20
      index results:[result: :negative], age: 10

      response = query(order_by: :age)

      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[0]["age"]).to eq(10)
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[1]["age"]).to eq(20)
    end

    it "should order by age desc" do
      index results:[result: :positive], age: 20
      index results:[result: :negative], age: 10

      response = query(order_by: "-age")

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

      response = query(order_by: "age,gender")

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

      response = query(order_by: "age,-gender")

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

      response = query(location: 2).sort_by do |event|
        event["results"].first["result"]
      end

      expect(response.size).to eq(2)
      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[1]["results"].first["result"]).to eq("positive")

      response = query(location: 1).sort_by do |event|
        event["results"].first["result"]
      end

      expect(response.size).to eq(3)
      expect(response[0]["results"].first["result"]).to eq("negative")
      expect(response[1]["results"].first["result"]).to eq("positive")
      expect(response[2]["results"].first["result"]).to eq("positive with riff")
    end

    it "groups by administrative level" do
      expect_any_instance_of(Cdx::Api::Elasticsearch::IndexedField).to receive(:target_grouping_values) do |obj, grouping_def, values|
        case values
        when 0
          [1]
        when 1
          [2, 5]
        else
          fail
        end
      end.exactly(2).times

      index results: [result: "negative"], parent_locations: [1, 2, 3]
      index results: [result: "positive"], parent_locations: [1, 2, 4]
      index results: [result: "positive with riff"], parent_locations: [1, 5]

      response = query(group_by: {admin_level: 1})
      expect(response).to eq([
        {"location"=>2, count: 2},
        {"location"=>5, count: 1}
      ])

      response = query(group_by: {admin_level: 0})

      expect(response).to eq([
        {"location"=>1, count: 3}
      ])
    end
  end
end
