require 'spec_helper'

describe "Cdx::Api Multi" do

  include_context "elasticsearch index"
  include_context "cdx api helpers"

  def multi_query(queries)
    Cdx::Api::Elasticsearch::MultiQuery.new(queries.map(&:with_indifferent_access)).execute
  end

  describe "with two different filters" do
    before(:each) do
      index results: [result: :positive], system_user: "jdoe"
      index results: [result: :negative], system_user: "mmajor"
      index results: [result: :positive], age: 10
      index results: [result: :negative], age: 20
    end

    let(:responses) { multi_query([{system_user: "jdoe"}, {min_age: 15}]) }

    it "should return one response per query" do
      expect(responses.length).to eq(2)
    end

    it "should return correct results" do
      expect_one_result_with_field "system_user", "jdoe", response: responses[0]['events']
      expect_one_result "negative", min_age: 15, response: responses[1]['events']
    end

    it "should return correct total counts" do
      responses.each do |response|
        expect(response['total_count']).to eq(1)
      end
    end
  end

end
