require 'spec_helper'

describe "formats of document stored" do

  before(:each) do
    api.client.delete_by_query index: "cdx_events", body: { query: { match_all: {} } } rescue nil
  end

  let(:custom_document_format) {
    Cdx::Api::Elasticsearch::CustomDocumentFormat.new({
      "assay_name" => "assay",
      "device_uuid" => "device_id",
      "location" => "place"
    })
  }
  let(:api)  { setup_api custom_document_format }

  it "should retrieve documents in standard format even if they are stored with different names" do
    es_index start_time: time(2013, 1, 1), assay: "ASSAY001"

    response = query_events since: time(2013, 1, 1)

    expect(response.size).to eq(1)
    event = response[0]

    # response comes in CDP API format
    expect(event["assay_name"]).to eq("ASSAY001")
    expect(event.include? "assay").to be_falsy
  end

  it "should allow to search using standard format even if fields are stored with different names" do
    es_index start_time: time(2013, 1, 1), assay: "ASSAY001"
    es_index start_time: time(2013, 1, 1), assay: "ASSAY002"

    response = query_events since: time(2013, 1, 1), assay_name: "ASSAY001"

    expect(response.size).to eq(1)
  end

  it "should allow to search by device with custom document field name" do
    es_index start_time: time(2013, 1, 1), device_id: "1234"
    es_index start_time: time(2013, 1, 1), device_id: "5678"

    response = query_events since: time(2013, 1, 1), device: "1234"
    expect(response.size).to eq(1)
    expect(response[0]["device_uuid"]).to eq("1234")
  end

  it "allows to group by field saved with custom name using standard name" do
    es_index start_time: time(2013, 1, 1), assay: "ASSAY001"
    es_index start_time: time(2013, 1, 1), assay: "ASSAY001"
    es_index start_time: time(2013, 1, 1), assay: "ASSAY002"

    response = query_events since: time(2013, 1, 1), group_by: :assay_name
    expect(response.size).to eq(2)

    groups_by_assay = Hash[response.map { |group| [ group["assay_name"], group[:count] ] }]
    expect(groups_by_assay["ASSAY001"]).to eq(2)
    expect(groups_by_assay["ASSAY002"]).to eq(1)
  end

  it "allows to group by field saved with custom name using standard name (omitting '_id' suffix)" do
    es_index start_time: time(2013, 1, 1), device_id: "1234"
    es_index start_time: time(2013, 1, 1), device_id: "1234"
    es_index start_time: time(2013, 1, 1), device_id: "5678"

    response = query_events since: time(2013, 1, 1), group_by: :device
    expect(response.size).to eq(2)

    groups_by_device = Hash[response.map { |group| [ group["device"], group[:count] ] }]
    expect(groups_by_device["1234"]).to eq(2)
    expect(groups_by_device["5678"]).to eq(1)
  end

  it "sorts using format specific event date field by default" do
    es_index start_time: time(2013, 1, 2)
    es_index start_time: time(2013, 1, 1)
    es_index start_time: time(2013, 1, 3)

    response = query_events since: time(2013, 1, 1)
    event_dates = response.map { |event| event["start_time"] }

    expect(event_dates.sort).to eq([
      time(2013,1,1),
      time(2013,1,2),
      time(2013,1,3)
    ])
  end

  it "allows to group by start time" do
    es_index start_time: time(2013, 1, 1), assay: "ASSAY001"
    es_index start_time: time(2013, 1, 1), assay: "ASSAY001"
    es_index start_time: time(2013, 1, 1), assay: "ASSAY002"

    response = query_events since: time(2013, 1, 1), group_by: "year(start_time)"
    expect(response).to eq([{"start_time" => "2013", :count => 3}])
  end

  it "allows searching by location with custom name" do
    es_index parent_places: [1, 2, 3]
    es_index parent_places: [1, 2, 4]
    es_index parent_places: [1, 5, 6]

    response = query_events location: 2
    expect(response.count).to eq(2)
  end

  it "allows grouping by location with custom name" do
    es_index place: [admin_level_0: 1, admin_level_1: 2, admin_level2: 3]
    es_index place: [admin_level_0: 1, admin_level_1: 2, admin_level2: 4]
    es_index place: [admin_level_0: 1, admin_level_1: 5, admin_level2: 6]

    response = query_events group_by: { admin_level: 1 }
    expect(response).to eq([{"location" => "2", :count => 2}, {"location" => "5", :count => 1}])

    response = query_events group_by: { admin_level: 0 }
    expect(response).to eq([{"location" => "1", :count => 3}])
  end

  def query_events(query)
    query(query)["events"]
  end

  def query(query)
    Cdx::Api::Elasticsearch::Query.new(query.with_indifferent_access, api).execute
  end

  def setup_api(document_format)
    api = Cdx::Api::Service.new
    api.setup do |config|
      config.index_name_pattern = "cdx_events*"
      config.template_name_pattern = "cdx_events*"
      config.document_format = document_format
      # config.log = true
    end

    api.client.indices.delete index: "cdx_events" rescue nil
    api.initialize_default_template "cdx_events_template"
    api
  end

  def es_index doc
    api.client.index index: "cdx_events", type: "event", body: doc, refresh: true
  end

  def time(year, month, day, hour = 12, minute = 0, second = 0)
    Time.utc(year, month, day, hour, minute, second).iso8601
  end

end
