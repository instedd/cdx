require 'spec_helper'

describe DeviceEventImporter do

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

  it 'parses a csv from sync dir' do
    manifest = Manifest.create! definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1.1.0",
          "device_models": "#{device.device_model.name}",
          "source" : { "type" : "csv"}
        },
        "field_mapping" : {"event" : [{
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
        ]}
      }
    }

    DeviceEventImporter.new.import_from sync_dir

    events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["error_code"] }
    event = events.first["_source"]
    event["error_code"].should eq("0")
    event["result"].should eq("positive")
    event = events.last["_source"]
    event["error_code"].should eq("1")
    event["result"].should eq("negative")
  end


end
