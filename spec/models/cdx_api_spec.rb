require 'spec_helper'

describe Cdx::Api do
  def index(body)
    Cdx::Api.client.index index: "cdx_events", type: "event", body: body, refresh: true
  end

  def query(query)
    Cdx::Api.query(query.with_indifferent_access)
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
end
