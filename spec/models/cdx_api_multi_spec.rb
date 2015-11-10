require 'spec_helper'

describe "Cdx::Api Multi", elasticsearch: true do
  include_context "cdx api helpers"

  let!(:device) {Device.make}
  let!(:institution) { device.institution }

  def multi_query(queries)
    Cdx::Api::Elasticsearch::MultiQuery.new(queries, Cdx::Fields.test).execute
  end

  describe "with two different filters" do
    before(:each) do
      index_with_test_result test: {assays: [{result: :positive}], site_user: "jdoe"}
      index_with_test_result test: {assays: [{result: :negative}], site_user: "mmajor"}
      index_with_test_result test: {assays: [{result: :positive}]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)}
      index_with_test_result test: {assays: [{result: :negative}]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)}
    end

    let(:responses) { multi_query([{'test.site_user' => "jdoe"}, {'encounter.patient_age' => "15yo.."}]) }

    it "should return one response per query" do
      expect(responses.length).to eq(2)
    end

    it "should return correct results" do
      expect_one_event_with_field "test", "site_user", "jdoe", response: responses[0]['tests']
      expect_one_result "negative", "encounter.patient_age" => "15yo..", response: responses[1]['tests']
    end

    it "should return correct total counts" do
      responses.each do |response|
        expect(response['total_count']).to eq(1)
      end
    end
  end
end
