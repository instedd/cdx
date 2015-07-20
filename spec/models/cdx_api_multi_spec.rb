require 'spec_helper'

describe "Cdx::Api Multi" do

  include_context "elasticsearch index"
  include_context "cdx api helpers"

  def multi_query(queries)
    Cdx::Api::Elasticsearch::MultiQuery.new(queries).execute
  end

  describe "with two different filters" do
    before(:each) do
      index test: {assays: [{qualitative_result: :positive}]}, device: {lab_user: "jdoe"}
      index test: {assays: [{qualitative_result: :negative}]}, device: {lab_user: "mmajor"}
      index test: {assays: [{qualitative_result: :positive}], patient_age: {years: 10}}
      index test: {assays: [{qualitative_result: :negative}], patient_age: {years: 20}}
    end

    let(:responses) { multi_query([{'device.lab_user' => "jdoe"}, {'test.patient_age' => "15yo.."}]) }

    it "should return one response per query" do
      expect(responses.length).to eq(2)
    end

    it "should return correct results" do
      expect_one_event_with_field "device", "lab_user", "jdoe", response: responses[0]['tests']
      expect_one_qualitative_result "negative", "test.patient_age" => "15yo..", response: responses[1]['tests']
    end

    it "should return correct total counts" do
      responses.each do |response|
        expect(response['total_count']).to eq(1)
      end
    end
  end

end
