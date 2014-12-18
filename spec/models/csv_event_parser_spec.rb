require 'spec_helper'

describe CSVEventParser do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  before(:each) do
    File.open(Rails.root.join("spec", "support", "#{device.secret_key}-#{DateTime.now.strftime('%Y%m%d%H%M%S')}.csv"), "w") do |io|
      io << %{error_code,result\n0,positive\n1,negative}
    end
  end

  def all_elasticsearch_events
    client = fresh_client_for institution.elasticsearch_index_name
    client.search(index: institution.elasticsearch_index_name)["hits"]["hits"]
  end

  it 'parses a csv' do
    manifest = Manifest.make definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{device.device_model.name}",
          "source_data_type" : "csv"
        },
        "field_mapping" : [{
            "target_field" : "error_code",
            "selector" : "error_code",
            "core" : true,
            "type" : "integer"
          },
          {
            "target_field" : "result",
            "selector" : "result",
            "core" : true,
            "type" : "enum",
            "options" : [
              "positive",
              "negative"
            ]
          }
        ]
      }
    }

    CSVEventParser.new.import_from Rails.root.join("spec", "support")

    events = all_elasticsearch_events.sort_by { |event| event["_source"]["error_code"] }
    event = events.first["_source"]
    event["error_code"].should eq("0")
    event["result"].should eq("positive")
    event = events.last["_source"]
    event["error_code"].should eq("1")
    event["result"].should eq("negative")
  end
end
