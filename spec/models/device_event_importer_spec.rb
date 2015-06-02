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
      "field_mapping" : {"test" : [{
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

      tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["error_code"] }
      test = tests.first["_source"]
      test["error_code"].should eq(0)
      test["result"].should eq("positive")
      test = tests.last["_source"]
      test["error_code"].should eq(1)
      test["result"].should eq("negative")
    end

    it 'parses a csv in utf 16' do
      manifest

      write_file(%{error_code;result\r\n0;positivo\r\n1;inválido\r\n}, 'csv', nil, 'UTF-16LE')
      CharDet.stub(:detect).and_return('encoding' => 'UTF-16LE', 'confidence' => 1.0)
      DeviceEventImporter.new.import_from sync_dir

      tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["error_code"] }
      test = tests.first["_source"]
      test["error_code"].should eq(0)
      test["result"].should eq("positivo")
      test = tests.last["_source"]
      test["error_code"].should eq(1)
      test["result"].should eq("inválido")
    end

  end

  context "json" do

    let(:source) { "json" }

    it 'parses a json from sync dir' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json')
      DeviceEventImporter.new("*.json").import_from sync_dir

      tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["error_code"] }
      test = tests.first["_source"]
      test["error_code"].should eq(0)
      test["result"].should eq("positive")
      test = tests.last["_source"]
      test["error_code"].should eq(1)
      test["result"].should eq("negative")
    end

    it 'parses a json from sync dir registering multiple extensions' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json')
      DeviceEventImporter.new("*.{csv,json}").import_from sync_dir

      tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["error_code"] }
      test = tests.first["_source"]
      test["error_code"].should eq(0)
      test["result"].should eq("positive")
      test = tests.last["_source"]
      test["error_code"].should eq(1)
      test["result"].should eq("negative")
    end

    it 'parses a json from sync dir registering multiple extensions using import single' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json', 'mytestfile')
      DeviceEventImporter.new("*.{csv,json}").import_single(sync_dir, File.join(sync_dir.inbox_path(device.uuid), "mytestfile.json"))

      tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["error_code"] }
      test = tests.first["_source"]
      test["error_code"].should eq(0)
      test["result"].should eq("positive")
      test = tests.last["_source"]
      test["error_code"].should eq(1)
      test["result"].should eq("negative")
    end

  end

  context "real scenarios" do

    def copy_sample_csv(name)
      copy_sample(name, 'csvs')
    end

    def copy_sample_xml(name)
      copy_sample(name, 'xmls')
    end

    def copy_sample(name, format)
      FileUtils.cp File.join(Rails.root, 'spec', 'fixtures', format, name), sync_dir.inbox_path(device.uuid)
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

        tests = all_elasticsearch_tests_for(device.institution)
        tests.should have(18).items
        tests.map{|e| e['_source']['start_time']}.should =~ ['2014-09-09T17:07:32+00:00', '2014-10-28T13:00:58+00:00', '2014-10-28T17:24:34+00:00', '2015-02-10T18:10:28+00:00', '2015-03-03T19:27:36+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:35:19+00:00', '2015-03-31T18:34:08+00:00', '2015-03-31T18:34:08+00:00', '2015-03-31T18:34:08+00:00', '2015-03-31T18:34:08+00:00', '2014-11-05T08:38:30+00:00', '2014-10-29T12:24:59+00:00', '2014-10-29T12:24:59+00:00', '2014-10-29T12:24:59+00:00', '2014-10-29T12:24:59+00:00']
      end
    end

    context 'genoscan' do
      let(:device_model) { DeviceModel.make name: 'genoscan'}
      let!(:manifest) { load_manifest 'genoscan_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'genoscan_sample.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["results"][0]["result"] }
        tests.should have(13).items

        test = tests.first["_source"]
        test["results"][0]["condition"].should eq("mtb")
        test["results"][0]["result"].should eq("negative")

        test = tests.last["_source"]
        test["results"][0]["condition"].should eq("mtb")
        test["results"][0]["result"].should eq("positive_with_rif_and_inh")

        dbtests = TestResult.all
        dbtests.should have(13).items
        dbtests.map(&:uuid).should =~ tests.map {|e| e['_source']['uuid']}
      end
    end

    context 'epicenter' do
      let(:device_model) { DeviceModel.make name: 'epicenter_es'}
      let!(:manifest) { load_manifest 'epicenter_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'epicenter_sample.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["results"][0]["result"] }
        tests.should have(29).items

        test = tests.first["_source"]
        test["results"][0]["condition"].should eq("mtb")
        test["results"][0]["result"].should eq("ethambutol_sensitive")

        test = tests.last["_source"]
        test["results"][0]["condition"].should eq("mtb")
        test["results"][0]["result"].should eq("thiosemicarbazone_invalid")

        dbtests = TestResult.all
        dbtests.should have(29).items
        dbtests.map(&:uuid).should =~ tests.map {|e| e['_source']['uuid']}

        Sample.count.should eq(3)
      end
    end

    context "epicenter headless" do
      let(:device_model) { DeviceModel.make name: 'epicenter_headless_es'}
      let!(:manifest) { load_manifest 'epicenter_headless_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'epicenter_headless_sample.csv'
        DeviceEventImporter.new("*.csv").import_from sync_dir

        tests = all_elasticsearch_tests_for(device.institution).sort_by { |test| test["_source"]["results"][0]["result"] }
        tests.should have(29).items

        test = tests.first["_source"]
        test["results"][0]["condition"].should eq("mtb")
        test["results"][0]["result"].should eq("ethambutol_sensitive")

        test = tests.last["_source"]
        test["results"][0]["condition"].should eq("mtb")
        test["results"][0]["result"].should eq("thiosemicarbazone_invalid")

        dbtests = TestResult.all
        dbtests.should have(29).items
        dbtests.map(&:uuid).should =~ tests.map {|e| e['_source']['uuid']}

        Sample.count.should eq(3)
      end
    end

    context 'fio' do
      let(:device_model) { DeviceModel.make name: 'FIO'}
      let!(:manifest) { load_manifest 'fio_manifest.json' }

      it 'parses xml' do
        copy_sample_xml 'fio_sample.xml'
        DeviceEventImporter.new("*.xml").import_from sync_dir

        tests = all_elasticsearch_tests_for(device.institution)
        tests.should have(1).items

        test = tests.first['_source']

        test['test_id'].should eq('12345678901234567890')
        test['gender'].should eq('female')
        test['age'].should eq(25)
        test['custom_fields']['pregnancy_status'].should eq('Not Pregnant')
        test['sample_id'].should eq('0987654321')
        test['start_time'].should  eq('2015-05-18T12:34:56+05:00')
        test['assay_name'].should eq('SD_MALPFPV_02_02')
        test['status'].should eq('success')

        test_results = test['results']
        test_results.size.should eq(2)
        test_results.first['result'].should eq('Positive')
        test_results.first['condition'].should eq('HRPII')
        test_results.second['result'].should eq('Negative')
        test_results.second['condition'].should eq('pLDH')

        TestResult.count.should eq(1)
        db_test = TestResult.first
        db_test.uuid.should eq(test['uuid'])
        db_test.test_id.should eq('12345678901234567890')
      end
    end

  end

end
