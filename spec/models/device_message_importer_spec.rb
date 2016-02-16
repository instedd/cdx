# encoding UTF8
require 'spec_helper'
require 'fileutils'

describe DeviceMessageImporter, elasticsearch: true do

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

  let(:manifest) do Manifest.create! device_model: device.device_model, definition: %{
    {
      "metadata": {
        "version": "1",
        "api_version": "#{Manifest::CURRENT_VERSION}",
        "conditions": ["mtb"],
        "source" : { "type" : "#{source}"}
      },
      "field_mapping" : {
        "test.error_code" : {"lookup": "error_code"},
        "test.assays.result" : {
          "case": [
          {"lookup": "result"},
          [
            {"when": "positivo", "then" : "positive"},
            {"when": "positive", "then" : "positive"},
            {"when": "negative", "then" : "negative"},
            {"when": "negativo", "then" : "negative"},
            {"when": "inválido", "then" : "n/a"}
          ]
        ]},
        "test.status" : {
          "case": [
          {"lookup": "result"},
          [
            {"when": "inválido", "then" : "invalid"},
            {"when": "invalid", "then" : "invalid"},
            {"when": "*", "then" : "success"}
          ]
        ]}
      }
    }
  }
  end

  context "csv" do
    let(:source) { "csv" }

    it 'parses a csv from sync dir' do
      manifest
      write_file(%{error_code;result\n0;positive\n1;negative}, 'csv')
      DeviceMessageImporter.new.import_from sync_dir

      expect(DeviceMessage.first.index_failure_reason).to be_nil
      tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
      test = tests.first["_source"]["test"]
      expect(test["error_code"]).to eq(0)
      expect(test["assays"].first["result"]).to eq("positive")
      test = tests.last["_source"]["test"]
      expect(test["error_code"]).to eq(1)
      expect(test["assays"].first["result"]).to eq("negative")
    end

    it 'parses a csv in utf 16' do
      manifest

      write_file(%{error_code;result\r\n0;positivo\r\n1;inválido\r\n}, 'csv', nil, 'UTF-16LE')
      allow(CharDet).to receive(:detect).and_return('encoding' => 'UTF-16LE', 'confidence' => 1.0)
      DeviceMessageImporter.new.import_from sync_dir

      expect(DeviceMessage.first.index_failure_reason).to be_nil
      tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
      test = tests.first["_source"]["test"]
      expect(test["error_code"]).to eq(0)
      expect(test["assays"].first["result"]).to eq("positive")
      test = tests.last["_source"]["test"]
      expect(test["error_code"]).to eq(1)
      expect(test["assays"].first["result"]).to eq("n/a")
    end
  end

  context "json" do

    let(:source) { "json" }

    it 'parses a json from sync dir' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json')
      DeviceMessageImporter.new("*.json").import_from sync_dir

      expect(DeviceMessage.first.index_failure_reason).to be_nil
      tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
      test = tests.first["_source"]["test"]
      expect(test["error_code"]).to eq(0)
      expect(test["assays"].first["result"]).to eq("positive")
      test = tests.last["_source"]["test"]
      expect(test["error_code"]).to eq(1)
      expect(test["assays"].first["result"]).to eq("negative")
    end

    it 'parses a json from sync dir registering multiple extensions' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json')
      DeviceMessageImporter.new("*.{csv,json}").import_from sync_dir

      expect(DeviceMessage.first.index_failure_reason).to be_nil
      tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
      test = tests.first["_source"]["test"]
      expect(test["error_code"]).to eq(0)
      expect(test["assays"].first["result"]).to eq("positive")
      test = tests.last["_source"]["test"]
      expect(test["error_code"]).to eq(1)
      expect(test["assays"].first["result"]).to eq("negative")
    end

    it 'parses a json from sync dir registering multiple extensions using import single' do
      manifest
      write_file('[{"error_code": "0", "result": "positive"}, {"error_code": "1", "result": "negative"}]', 'json', 'mytestfile')
      DeviceMessageImporter.new("*.{csv,json}").import_single(sync_dir, File.join(sync_dir.inbox_path(device.uuid), "mytestfile.json"))

      expect(DeviceMessage.first.index_failure_reason).to be_nil
      tests = all_elasticsearch_tests.sort_by { |test| test["_source"]["test"]["error_code"] }
      test = tests.first["_source"]["test"]
      expect(test["error_code"]).to eq(0)
      expect(test["assays"].first["result"]).to eq("positive")
      test = tests.last["_source"]["test"]
      expect(test["error_code"]).to eq(1)
      expect(test["assays"].first["result"]).to eq("negative")
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
      Manifest.create! device_model: device_model, definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', name))
    end

    context 'epicenter headless_es' do
      let!(:device_model) { DeviceModel.make name: 'epicenter_headless_es' }
      let!(:manifest)    { load_manifest 'epicenter_m.g.i.t._spanish_manifest.json' }

      it "parses csv in utf-16le" do
        copy_sample_csv 'epicenter_headless_sample_utf16.csv'
        DeviceMessageImporter.new("*.csv").import_from sync_dir

        expect(DeviceMessage.first.index_failure_reason).to be_nil
        tests = all_elasticsearch_tests
        expect(tests.size).to eq(18)
        expect(tests.map{|e| e['_source']['test']['start_time']}).to match_array(['2014-09-09T17:07:32.000Z', '2014-10-28T13:00:58.000Z', '2014-10-28T17:24:34.000Z', '2015-02-10T18:10:28.000Z', '2015-03-03T19:27:36.000Z', '2015-03-31T18:35:19.000Z', '2015-03-31T18:35:19.000Z', '2015-03-31T18:35:19.000Z', '2015-03-31T18:35:19.000Z', '2015-03-31T18:34:08.000Z', '2015-03-31T18:34:08.000Z', '2015-03-31T18:34:08.000Z', '2015-03-31T18:34:08.000Z', '2014-11-05T08:38:30.000Z', '2014-10-29T12:24:59.000Z', '2014-10-29T12:24:59.000Z', '2014-10-29T12:24:59.000Z', '2014-10-29T12:24:59.000Z'])
      end
    end

    context 'cepheid' do
      let!(:device_model) { DeviceModel.make name: "GX Model I" }
      let!(:manifest)    { load_manifest 'cepheid_gene_xpert_manifest.json' }

      it "should parse cepheid's document" do
        copy_sample('cepheid_sample.json', 'jsons')
        DeviceMessageImporter.new("*.json").import_from sync_dir

        expect(DeviceMessage.first.index_failure_reason).to be_nil
        tests = all_elasticsearch_tests
        expect(tests.size).to eq(1)
        expect(tests.first['_source']['test']['start_time']).to eq('2015-04-07T18:31:20-05:00')
      end
    end

    context 'genoscan' do
      let(:device_model) { DeviceModel.make name: 'genoscan' }
      let!(:manifest) { load_manifest 'genoscan_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'genoscan_sample.csv'
        DeviceMessageImporter.new("*.csv").import_from sync_dir

        expect(DeviceMessage.first.index_failure_reason).to be_nil
        tests = all_elasticsearch_tests.sort_by do |test|
          test["_source"]["test"]["assays"][0]['result'] + test["_source"]["test"]["assays"][1]['result'] + test["_source"]["test"]["assays"][2]['result']
        end
        expect(tests.size).to eq(13)

        test = tests[0]["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("mtb")
        expect(test["assays"][0]["condition"]).to eq("mtb")
        expect(test["assays"][0]["result"]).to eq("negative")
        expect(test["assays"][1]["name"]).to eq("rif")
        expect(test["assays"][1]["condition"]).to eq("rif")
        expect(test["assays"][1]["result"]).to eq("negative")
        expect(test["assays"][2]["name"]).to eq("inh")
        expect(test["assays"][2]["condition"]).to eq("inh")
        expect(test["assays"][2]["result"]).to eq("negative")

        test = tests[1]["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("mtb")
        expect(test["assays"][0]["condition"]).to eq("mtb")
        expect(test["assays"][0]["result"]).to eq("positive")
        expect(test["assays"][1]["name"]).to eq("rif")
        expect(test["assays"][1]["condition"]).to eq("rif")
        expect(test["assays"][1]["result"]).to eq("negative")
        expect(test["assays"][2]["name"]).to eq("inh")
        expect(test["assays"][2]["condition"]).to eq("inh")
        expect(test["assays"][2]["result"]).to eq("negative")

        test = tests.last["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("mtb")
        expect(test["assays"][0]["condition"]).to eq("mtb")
        expect(test["assays"][0]["result"]).to eq("positive")
        expect(test["assays"][1]["name"]).to eq("rif")
        expect(test["assays"][1]["condition"]).to eq("rif")
        expect(test["assays"][1]["result"]).to eq("positive")
        expect(test["assays"][2]["name"]).to eq("inh")
        expect(test["assays"][2]["condition"]).to eq("inh")
        expect(test["assays"][2]["result"]).to eq("positive")

        dbtests = TestResult.all
        expect(dbtests.size).to eq(13)
        expect(dbtests.map(&:uuid)).to match_array(tests.map {|e| e['_source']['test']['uuid']})
      end
    end

    context 'alere q' do
      let(:device_model) { DeviceModel.make name: 'alere q' }
      let!(:manifest) { load_manifest 'alere_q_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'alere_q.csv'
        DeviceMessageImporter.new("*.csv").import_from sync_dir

        expect(DeviceMessage.first.index_failure_reason).to be_nil
        tests = all_elasticsearch_tests.sort_by do |test|
          test["_source"]["test"]["assays"][0]['result'] + test["_source"]["test"]["assays"][1]['result'] + test["_source"]["test"]["assays"][2]['result']
        end
        expect(tests.size).to eq(73)

        test = tests[0]["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("HIV-1 M/N")
        expect(test["assays"][0]["condition"]).to eq("hiv_1_m_n")
        expect(test["assays"][0]["result"]).to eq("negative")
        expect(test["assays"][1]["name"]).to eq("HIV-1 O")
        expect(test["assays"][1]["condition"]).to eq("hiv_1_o")
        expect(test["assays"][1]["result"]).to eq("negative")
        expect(test["assays"][2]["name"]).to eq("HIV-2")
        expect(test["assays"][2]["condition"]).to eq("hiv_2")
        expect(test["assays"][2]["result"]).to eq("negative")

        test = tests[1]["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("HIV-1 M/N")
        expect(test["assays"][0]["condition"]).to eq("hiv_1_m_n")
        expect(test["assays"][0]["result"]).to eq("negative")
        expect(test["assays"][1]["name"]).to eq("HIV-1 O")
        expect(test["assays"][1]["condition"]).to eq("hiv_1_o")
        expect(test["assays"][1]["result"]).to eq("negative")
        expect(test["assays"][2]["name"]).to eq("HIV-2")
        expect(test["assays"][2]["condition"]).to eq("hiv_2")
        expect(test["assays"][2]["result"]).to eq("negative")

        test = tests.last["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("HIV-1 M/N")
        expect(test["assays"][0]["condition"]).to eq("hiv_1_m_n")
        expect(test["assays"][0]["result"]).to eq("positive")
        expect(test["assays"][1]["name"]).to eq("HIV-1 O")
        expect(test["assays"][1]["condition"]).to eq("hiv_1_o")
        expect(test["assays"][1]["result"]).to eq("negative")
        expect(test["assays"][2]["name"]).to eq("HIV-2")
        expect(test["assays"][2]["condition"]).to eq("hiv_2")
        expect(test["assays"][2]["result"]).to eq("negative")

        dbtests = TestResult.all
        expect(dbtests.size).to eq(73)
        expect(dbtests.map(&:uuid)).to match_array(tests.map {|e| e['_source']['test']['uuid']})
      end
    end

    context 'alere pima' do
      let(:device_model) { DeviceModel.make name: 'alere pima' }
      let!(:manifest) { load_manifest 'alere_pima_manifest.json' }

      it 'parses csv' do
        copy_sample_csv 'alere_pima.csv'
        DeviceMessageImporter.new("*.csv").import_from sync_dir

        expect(DeviceMessage.first.index_failure_reason).to be_nil
        tests = all_elasticsearch_tests.sort_by do |test|
          (test["_source"]["test"]["error_description"] || "") +
            (test["_source"]["test"]["assays"].first['quantitative_result'].to_s || "")
        end
        expect(tests.size).to eq(38)

        test = tests[0]["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("PIMA CD4")
        expect(test["assays"][0]["condition"]).to eq("cd4_count")
        expect(test["assays"][0]["result"]).to eq("n/a")
        expect(test["assays"][0]["quantitative_result"]).to eq(1)

        test = tests.last["_source"]["test"]
        expect(test["assays"][0]["name"]).to eq("PIMA CD4")
        expect(test["assays"][0]["condition"]).to eq("cd4_count")
        expect(test["assays"][0]["result"]).to eq("n/a")
        expect(test["assays"][0]["quantitative_result"]).to eq(nil)
        expect(test["error_description"]).to eq('Test not finished Error 200')

        dbtests = TestResult.all
        expect(dbtests.size).to eq(38)
        expect(dbtests.map(&:uuid)).to match_array(tests.map {|e| e['_source']['test']['uuid']})
      end
    end

    context 'fio' do
      let(:device_model) { DeviceModel.make name: 'FIO' }
      let!(:manifest) { load_manifest 'fio_manifest.json' }

      it 'parses xml' do
        copy_sample_xml 'fio_sample.xml'
        DeviceMessageImporter.new("*.xml").import_from sync_dir

        expect(DeviceMessage.first.index_failure_reason).to be_nil
        tests = all_elasticsearch_tests
        expect(tests.size).to eq(1)

        test = tests.first['_source']

        expect(test['test']['id']).to eq('12345678901234567890')
        expect(test['patient']['gender']).to eq('female')
        expect(test['encounter']['patient_age']["years"]).to eq(25)
        expect(test['patient']['custom_fields']['pregnancy_status']).to eq('Not Pregnant')
        expect(test['sample']['id']).to eq('0987654321')
        expect(test['test']['start_time']).to  eq('2015-05-18T12:34:56+05:00')
        expect(test['test']['name']).to eq('SD_MALPFPV_02_02')
        expect(test['test']['status']).to eq('success')

        assays = test['test']['assays']
        expect(assays.size).to eq(2)
        expect(assays.first['result']).to eq('positive')
        expect(assays.first['quantitative_result']).to eq(23.45)
        expect(assays.first['name']).to eq('HRPII')
        expect(assays.second['result']).to eq('negative')
        expect(assays.second['quantitative_result']).to eq(0)
        expect(assays.second['name']).to eq('pLDH')

        expect(TestResult.count).to eq(1)
        db_test = TestResult.first
        expect(db_test.uuid).to eq(test['test']['uuid'])
        expect(db_test.test_id).to eq('12345678901234567890')
      end
    end


    context 'BDMicroImager' do
      let!(:device_model) { DeviceModel.make name: "BD MicroImager" }
      let!(:manifest)    { load_manifest 'bdmicro_imager_manifest.json' }

      it "should parse bdmicro's document" do
        copy_sample('bdmicro_imager_sample.json', 'jsons')
        DeviceMessageImporter.new("*.json").import_from sync_dir
        expect(DeviceMessage.first.index_failure_reason).to be_nil

        tests = all_elasticsearch_tests

        expect(tests.size).to eq(1)

        expect(tests.first['_source']['test']['error_code']).to eq(61)
        expect(tests.first['_source']['test']['id']).to eq("46")
        expect(tests.first['_source']['test']['custom_fields']['device_software_version']).to eq("00.02.03")

        expect(tests.first['_source']['test']['custom_fields']['tbcount1']).to eq("46.0")
        expect(tests.first['_source']['test']['custom_fields']['tbcount2']).to eq("56.0")
        expect(tests.first['_source']['test']['custom_fields']['tbpercent']).to eq("22.1")
        expect(tests.first['_source']['test']['custom_fields']['qcmagnification']).to eq("6.98")
        expect(tests.first['_source']['test']['custom_fields']['qcresolution']).to eq("5.0")
        expect(tests.first['_source']['test']['custom_fields']['cartridge_expiration_date']).to eq("2017-07-04T00:00:00.000Z")
        expect(tests.first['_source']['test']['custom_fields']['cartridge_number']).to eq("6000704000001")
        expect(tests.first['_source']['test']['custom_fields']['qc_date']).to eq("2017-07-04T00:00:00.000Z")
        expect(tests.first['_source']['test']['custom_fields']['qc_passed']).to eq("passed")

        expect(tests.first['_source']['test']['type']).to eq('qc')
        expect(tests.first['_source']['test']['name']).to eq('TBMI')
        expect(tests.first['_source']['test']['status']).to eq('error')
        expect(tests.first['_source']['test']['start_time']).to eq('2015-09-28T23:46:53.000Z')
        expect(tests.first['_source']['test']['end_time']).to eq('2015-09-29T01:33:17.000Z')

        expect( tests.first['_source']['test']['assays']).to eq [{"condition"=>"mtb", "result"=>"positive"}]
      end
    end

  end
end
