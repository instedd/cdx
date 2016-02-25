require 'spec_helper'

describe Device do

  context "blueprint" do
    def should_be_valid_with_instition_and_site(device)
      expect(device.institution).to_not be_nil
      expect(device.site).to_not be_nil
      expect(device).to be_valid
    end

    it "should have an institution and site if not specified" do
      should_be_valid_with_instition_and_site Device.make_unsaved
    end

    it "should allow institution override and keep a site" do
      should_be_valid_with_instition_and_site Device.make_unsaved(institution: Institution.make)
    end

    it "should allow site override and keep an institution" do
      should_be_valid_with_instition_and_site Device.make_unsaved(site: Site.make)
    end

    it "should allow creating a device from site association" do
      site = Site.make
      device = site.devices.make
      should_be_valid_with_instition_and_site device
      expect(device.site).to eq(site)
    end
  end

  context "validations" do

    it { is_expected.to validate_presence_of :device_model }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :institution }

    it "should validate unpublished device model to belong to the same institution" do
      device = Device.make_unsaved institution: Institution.make
      device.device_model = DeviceModel.make(:unpublished, institution: Institution.make)
      expect(device).to be_invalid

      device.device_model = DeviceModel.make(:unpublished, institution: device.institution)
      expect(device).to be_valid
    end

    it "should not validate published device model" do
      device = Device.make_unsaved institution: Institution.make
      device.device_model = DeviceModel.make(institution: Institution.make)
      expect(device).to be_valid
    end

    it "should not allow institution and institution of site be different" do
      device = Device.make_unsaved
      device.institution = Institution.make
      device.site = Site.make
      expect(device).to_not be_valid
    end

    it "should allow same institution and institution of site" do
      device = Device.make_unsaved
      device.institution = Institution.make
      device.site = Site.make institution: device.institution
      expect(device).to be_valid
    end

    it "should allow device without institution" do
      device = Device.make_unsaved institution: Institution.make
      device.site = nil
      expect(device).to be_valid
    end

    it "should require all FTP fields for Alere device" do
      device = Device.make_unsaved institution: Institution.make
      device.device_model = DeviceModel.make(institution: Institution.make, name: "Alere")
      expect(device).to be_invalid
    end

    it "should be valid with all FTP fields filled for Alere device" do
      device = Device.make_unsaved institution: Institution.make
      device.device_model = DeviceModel.make(institution: Institution.make, name: "Alere")
      device.ftp_password = "12345678"
      device.ftp_hostname = "Test"
      device.ftp_port = 3000
      device.ftp_directory = "test/"
      device.ftp_username = "Mary"
      expect(device).to be_valid
    end

    it "should not require FTP fields at all for non Alere device" do
      device = Device.make_unsaved institution: Institution.make
      device.device_model = DeviceModel.make(institution: Institution.make, name: "Not lere")
      expect(device).to be_valid
    end
  end

  context "within institution or site scope" do
    let(:institution) { Institution.make }
    let(:other_institution) { Institution.make }

    let(:site1)  { Site.make institution: institution }
    let(:site11) { Site.make :child, parent: site1 }
    let(:site12) { Site.make :child, parent: site1 }
    let(:site2)  { Site.make institution: institution }

    let(:device1)  { Device.make site: site1 }
    let(:device11) { Device.make site: site11 }
    let(:device12) { Device.make site: site12 }
    let(:device2)  { Device.make site: site2 }

    let(:other_device)  { Device.make institution: other_institution }

    it "should filter by institution" do
      expect(Device.within(institution)).to eq([device1, device11, device12, device2])
    end

    it "filtering by site should include self" do
      expect(Device.within(site1)).to include(device1)
    end

    it "filtering by site should include descendants" do
      expect(Device.within(site1)).to include(device11)
      expect(Device.within(site1)).to include(device12)
    end

    it "filtering by site should not include sibling" do
      expect(Device.within(site1)).to_not include(device2)
    end
  end

  context 'cascade destroy', elasticsearch: true do

    it "should delete device elements in cascade" do
      device = Device.make

      TestResult.create_and_index(
        core_fields: {"assays" =>["name" => "mtb", "condition" => "mtb", "result" => :positive]},
        device_messages: [ DeviceMessage.make(device: device) ])
      DeviceLog.make(device: device)
      DeviceCommand.make(device: device)

      device.destroy_cascade!

      expect(Device.count).to eq(0)
      expect(TestResult.count).to eq(0)
      expect(DeviceMessage.count).to eq(0)
      expect(DeviceLog.count).to eq(0)
      expect(DeviceCommand.count).to eq(0)

      refresh_index

      result = Cdx::Api::Elasticsearch::Query.new({}, Cdx::Fields.test).execute
      expect(result['total_count']).to eq(0)
    end

  end

  context 'secret key' do
    let(:device) { Device.new }

    before(:each) do
      expect(MessageEncryption).to receive(:secure_random).and_return('abc')
    end

    it 'should tell plain secret key' do
      device.set_key

      expect(device.plain_secret_key).to eq('abc')
    end

    it 'should store hashed secret key' do
      device.set_key

      expect(device.secret_key_hash).to eq(MessageEncryption.hash 'abc')
    end
  end

  context 'commands' do
    let(:device) { Device.make }

    it "doesn't have pending log requests" do
      expect(device.has_pending_log_requests?).to be(false)
    end

    it "has pending log requests" do
      device.request_client_logs
      expect(device.has_pending_log_requests?).to be(true)

      commands = device.device_commands.all
      expect(commands.count).to eq(1)
      expect(commands[0].name).to eq("send_logs")
      expect(commands[0].command).to be_nil
    end
  end

  context 'site_prefix' do
    let(:device) { Device.make }

    it "has a site_prefix" do
      expect(device.site_prefix).to eq(device.site.prefix)
    end
  end

  context "within" do
    let!(:site) { Site.make }
    let!(:subsite) { Site.make parent: site, institution: site.institution }
    let!(:other_site) { Site.make }
    let!(:device1) { Device.make site: site, institution: site.institution }
    let!(:device2) { Device.make site: subsite, institution: site.institution }
    let!(:device3) { Device.make site: other_site, institution: other_site.institution }
    let!(:device4) { Device.make site: nil, institution: site.institution }

    it "institution, no exclusion, should show devices from site, subsites and no site" do
      expect(Device.within(site.institution).to_a).to eq([device1, device2, device4])
    end

    it "institution, with exclusion, should show device with no site" do
      expect(Device.within(site.institution,true).to_a).to eq([device4])
    end

    it "site, no exclusion, should show devices from site and subsite" do
      expect(Device.within(site).to_a).to eq([device1, device2])
    end

    it "site, with exclusion, should show devices from site only" do
      expect(Device.within(site,true).to_a).to eq([device1])
    end

    it "institution should not show devices from other institutions" do
      expect(Device.within(other_site.institution).to_a).to eq([device3])
    end
  end
end
