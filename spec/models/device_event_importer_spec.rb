# encoding UTF8
require 'spec_helper'
require 'fileutils'

describe DeviceEventImporter, elasticsearch: true do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device_model) { DeviceModel.make name: 'test_model'}
  let(:device) {Device.make institution_id: institution.id, device_model: device_model}
  let(:sync_dir) { CDXSync::SyncDirectory.new(Dir.mktmpdir('sync')) }

  before do
    sync_dir.ensure_sync_path!
    sync_dir.ensure_client_sync_paths! device.uuid
  end

  def write_file(content, extension, name=nil, encoding='UTF-8')
    File.open(File.join(sync_dir.inbox_path(device.uuid), "#{name || DateTime.now.strftime('%Y%m%d%H%M%S')}.#{extension}"), "w", encoding: encoding) do |io|
      io << content
    end
  end

  let(:manifest) do Manifest.create! definition: %{
    {
      "metadata": {
        "version": "1",
        "api_version": "1.1.0",
        "device_models": "#{device.device_model.name}",
        "source" : { "type" : "#{source}"}
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
          "options" : [ "positive", "negative", "positivo", "negativo", "inválido" ]
        }
      ]}
    }
  }
  end

  context "csv" do

    let(:source) { "csv" }

    it 'parses a csv from sync dir' do
      manifest
      write_file(%{error_code;result\n0;positive\n1;negative}, 'csv')
      DeviceEventImporter.new.import_from sync_dir

      events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["error_code"] }
      event = events.first["_source"]
      event["error_code"].should eq(0)
      event["result"].should eq("positive")
      event = events.last["_source"]
      event["error_code"].should eq(1)
      event["result"].should eq("negative")
    end

    it 'parses a csv in utf 16' do
      manifest

      write_file(%{error_code;result\r\n0;positivo\r\n1;inválido\r\n}, 'csv', nil, 'UTF-16LE')
      CharDet.stub(:detect).and_return('encoding' => 'UTF-16LE', 'confidence' => 1.0)
      DeviceEventImporter.new.import_from sync_dir

      events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["error_code"] }
      event = events.first["_source"]
      event["error_code"].should eq(0)
      event["result"].should eq("positivo")
      event = events.last["_source"]
      event["error_code"].should eq(1)
      event["result"].should eq("inválido")
    end

  end

  context "json" do

    let(:source) { "json" }

    it 'parses a json from sync dir' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json')
      DeviceEventImporter.new("*.json").import_from sync_dir

      events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["error_code"] }
      event = events.first["_source"]
      event["error_code"].should eq(0)
      event["result"].should eq("positive")
      event = events.last["_source"]
      event["error_code"].should eq(1)
      event["result"].should eq("negative")
    end

    it 'parses a json from sync dir registering multiple extensions' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json')
      DeviceEventImporter.new("*.{csv,json}").import_from sync_dir

      events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["error_code"] }
      event = events.first["_source"]
      event["error_code"].should eq(0)
      event["result"].should eq("positive")
      event = events.last["_source"]
      event["error_code"].should eq(1)
      event["result"].should eq("negative")
    end

    it 'parses a json from sync dir registering multiple extensions using import single' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json', 'mytestfile')
      DeviceEventImporter.new("*.{csv,json}").import_single(sync_dir, File.join(sync_dir.inbox_path(device.uuid), "mytestfile.json"))

      events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["error_code"] }
      event = events.first["_source"]
      event["error_code"].should eq(0)
      event["result"].should eq("positive")
      event = events.last["_source"]
      event["error_code"].should eq(1)
      event["result"].should eq("negative")
    end

  end

  context "real scenarios" do

    def copy_sample_csv(name)
      FileUtils.cp File.join(Rails.root, 'spec', 'fixtures', 'csvs', name), sync_dir.inbox_path(device.uuid)
    end

    def load_manifest(name)
      Manifest.create! definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', name))
    end

    context 'epicenter headless_es' do
      let(:device_model) { DeviceModel.make name: 'epicenter_headless_es'}
      let!(:manifest)    { load_manifest 'epicenter_headless_es_manifest.json' }

      it "parses csv in utf-16le" do
        copy_sample_csv 'epicenter_headless_sample_utf16.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        events = all_elasticsearch_events_for(device.institution)
        events.should have(18).items
        events.map{|e| e['_source']['start_time']}.should =~ ['2014-09-09T17:07:32+00:00', '2014-10-28T13:00:58+00:00', '2014-10-28T17:24:34+00:00', '2015-02-10T18:10:28+00:00', '2015-03-03T19:27:36+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:34:08+00:00', '2015-03-31T18:34:08+00:00', '2015-03-31T18:34:08+00:00', '2015-03-31T18:34:08+00:00', '2014-11-05T08:38:30+00:00', '2014-10-29T12:24:59+00:00', '2014-10-29T12:24:59+00:00', '2014-10-29T12:24:59+00:00', '2014-10-29T12:24:59+00:00']
      end
    end

    context 'genoscan' do
      let(:device_model) { DeviceModel.make name: 'genoscan'}
      let!(:manifest) { load_manifest 'genoscan_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'genoscan_sample.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["results"][0]["result"] }
        events.should have(13).items

        event = events.first["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("negative")

        event = events.last["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("positive_with_rif_and_inh")

        dbevents = Event.all
        dbevents.should have(13).items
        dbevents.map(&:uuid).should =~ events.map {|e| e['_source']['uuid']}
      end
    end

    context 'epicenter' do
      let(:device_model) { DeviceModel.make name: 'epicenter_es'}
      let!(:manifest) { load_manifest 'epicenter_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'epicenter_sample.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["results"][0]["result"] }
        events.should have(29).items

        event = events.first["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("ethambutol_sensitive")

        event = events.last["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("thiosemicarbazone_invalid")

        dbevents = Event.all
        dbevents.should have(29).items
        dbevents.map(&:uuid).should =~ events.map {|e| e['_source']['uuid']}

        dbevents = Sample.all
        dbevents.should have(3).items
      end
    end

    context "epicenter headless" do
      let(:device_model) { DeviceModel.make name: 'epicenter_headless_es'}
      let!(:manifest) { load_manifest 'epicenter_headless_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'epicenter_headless_sample.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        events = all_elasticsearch_events_for(device.institution).sort_by { |event| event["_source"]["results"][0]["result"] }
        events.should have(29).items

        event = events.first["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("ethambutol_sensitive")

        event = events.last["_source"]
        event["results"][0]["condition"].should eq("mtb")
        event["results"][0]["result"].should eq("thiosemicarbazone_invalid")

        dbevents = Event.all
        dbevents.should have(29).items
        dbevents.map(&:uuid).should =~ events.map {|e| e['_source']['uuid']}

        dbevents = Sample.all
        dbevents.should have(3).items
      end
    end

  end

end
