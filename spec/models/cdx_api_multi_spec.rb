require 'spec_helper'

describe "Cdx::Api Multi", elasticsearch: true do
  include_context "cdx api helpers"

  def multi_query(queries)
    Cdx::Api::Elasticsearch::MultiQuery.new(queries).execute
  end

  describe "with two different filters" do
    before(:each) do
      index test: {assays: [{result: :positive}], lab_user: "jdoe"}
      index test: {assays: [{result: :negative}], lab_user: "mmajor"}
      index test: {assays: [{result: :positive}], patient_age: Cdx::Field::DurationField.years(10)}
      index test: {assays: [{result: :negative}], patient_age: Cdx::Field::DurationField.years(20)}
    end

    let(:responses) { multi_query([{'test.lab_user' => "jdoe"}, {'test.patient_age' => "15yo.."}]) }

    it "should return one response per query" do
      expect(responses.length).to eq(2)
    end

    it "should return correct results" do
      expect_one_event_with_field "test", "lab_user", "jdoe", response: responses[0]['tests']
      expect_one_result "negative", "test.patient_age" => "15yo..", response: responses[1]['tests']
    end

    it "should return correct total counts" do
      responses.each do |response|
        expect(response['total_count']).to eq(1)
      end
    end
  end
end
