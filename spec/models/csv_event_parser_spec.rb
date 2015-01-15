require 'spec_helper'

describe CSVEventParser do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:sync_dir) { CDXSync::SyncDirectory.new(Dir.mktmpdir('sync')) }

  before do
    sync_dir.ensure_sync_path!
    sync_dir.ensure_client_sync_paths! device.secret_key
  end

  before(:each) do
    File.open(File.join(sync_dir.inbox_path(device.secret_key), "#{DateTime.now.strftime('%Y%m%d%H%M%S')}.csv"), "w") do |io|
      io << %{error_code;result\n0;positive\n1;negative}
    end
  end

  def all_elasticsearch_events
    client = fresh_client_for institution.elasticsearch_index_name
    client.search(index: institution.elasticsearch_index_name)["hits"]["hits"]
  end

  it 'parses a csv' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{device.device_model.name}",
          "source_data_type" : "csv"
        },
        "field_mapping" : [{
            "target_field" : "error_code",
            "source" : {"lookup": "error_code"},
            "core" : true,
            "type" : "integer"
          },
          {
            "target_field" : "result",
            "source" : {"lookup": "result"},
            "core" : true,
            "type" : "enum",
            "options" : [ "positive", "negative" ]
          }
        ]
      }
    }

    CSVEventParser.new.import_from sync_dir

    events = all_elasticsearch_events.sort_by { |event| event["_source"]["error_code"] }
    event = events.first["_source"]
    event["error_code"].should eq("0")
    event["result"].should eq("positive")
    event = events.last["_source"]
    event["error_code"].should eq("1")
    event["result"].should eq("negative")
  end

  it 'parses genoscan csv' do
    manifest = Manifest.create! definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', 'genoscan_manifest.json'))

    device = Device.make institution_id: institution.id, device_model: DeviceModel.find_by_name('genoscan')

    CSVEventParser.new.load_for_device(IO.read(File.join(Rails.root, 'public', 'genoscan_sample.csv')), device.secret_key)
    events = all_elasticsearch_events.sort_by { |event| event["_source"]["results"][0]["result"] }
    event = events.first["_source"]
    event["results"][0]["condition"].should eq("mtb")
    event["results"][0]["result"].should eq("positive")
    event = events.last["_source"]
    event["results"][0]["condition"].should eq("mtb")
    event["results"][0]["result"].should eq("positive_with_rmp_and_inh")
  end
end
