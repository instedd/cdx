require 'spec_helper'
require 'policy_spec_helper'

describe TestResultQuery, elasticsearch: true do

  let(:user)            {User.make}
  let(:user_2)          {User.make}

  let(:institution)     {Institution.make user_id: user.id}
  let(:institution_2)   {Institution.make user_id: user.id}
  let(:institution_3)   {Institution.make user_id: user.id}

  let(:site)      {Site.make institution: institution}
  let(:site_2)    {Site.make institution: institution_2}
  let(:site_3)    {Site.make institution: institution_3}
  let(:site_4)    {Site.make institution: institution}

  let(:user_device)     {Device.make institution_id: institution.id, site: site}
  let(:user_device_2)   {Device.make institution_id: institution.id, site: site}
  let(:user_device_3)   {Device.make institution_id: institution_2.id, site: site_2}
  let(:user_device_4)   {Device.make institution_id: institution_3.id, site: site_3}
  let(:user_device_5)   {Device.make institution_id: institution.id, site: site_4}
  let(:non_user_device) {Device.make}

  let(:core_fields) { {"test" => {"results" =>["condition" => "mtb", "result" => :positive]}} }

  context "policies" do
    it "applies institution policy" do
      TestResult.create_and_index(core_fields: {"results" =>["condition" => "mtb", "result" => :positive]}, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: {"results" =>["condition" => "mtb", "result" => :negative]}, device_messages:[DeviceMessage.make(device: non_user_device)])

      refresh_index

      result = TestResultQuery.for({"condition" => 'mtb'}, user).execute

      expect(result['total_count']).to eq(1)
      expect(result['tests'].first['test']['results'].first['result']).to eq('positive')
    end

    it "delegates all tests from a user" do
      TestResult.create_and_index(core_fields: {"results" =>["condition" => "mtb", "result" => :positive]}, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: {"results" =>["condition" => "mtb", "result" => :negative]}, device_messages:[DeviceMessage.make(device: user_device_3)])

      refresh_index

      grant(user, user_2, "testResult", QUERY_TEST)

      result = TestResultQuery.for({"condition" => 'mtb'}, user_2).execute

      expect(result['total_count']).to eq(2)
    end

    it "does not fail if no device is indexed for the institution yet" do
      institution

      refresh_index

      result = TestResultQuery.for({"condition" => 'mtb'}, user).execute

      expect(result['total_count']).to eq(0)
      expect(result['tests']).to eq([])
    end

    it "should not access any test if has no policy" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])

      refresh_index

      result = TestResultQuery.for({"condition" => 'mtb'}, User.new).execute

      expect(result['total_count']).to eq(0)
      expect(result['tests']).to eq([])
    end

    it "applies institution.id filter" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device_2)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device_3)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device_4)])

      refresh_index

      result = TestResultQuery.for({"institution.uuid" => institution_3.uuid}, user).execute
      expect(result['total_count']).to eq(1)
    end

    it "disallows viewing another institution's tests" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: non_user_device)])

      refresh_index

      result = TestResultQuery.for({"institution.id" => [non_user_device.institution.id.to_s, institution.id]}, user).execute
      expect(result['total_count']).to eq(1)
    end

    it "have access with policy by institution" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device_3)])

      refresh_index

      grant(user, user_2, "testResult?institution=#{institution.id}", QUERY_TEST)

      result = TestResultQuery.for({"condition" => 'mtb'}, user_2).execute
      expect(result['total_count']).to eq(1)
    end

    it "have access with policy by site" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device_5)])

      refresh_index

      grant(user, user_2, "testResult?site=#{site.id}", QUERY_TEST)

      result = TestResultQuery.for({"condition" => 'mtb'}, user_2).execute
      expect(result['total_count']).to eq(1)
    end

    it "have access with policy by device" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device_2)])

      refresh_index

      grant(user, user_2, "testResult?device=#{user_device.id}", QUERY_TEST)

      result = TestResultQuery.for({"condition" => 'mtb'}, user_2).execute
      expect(result['total_count']).to eq(1)
    end

    it "has access to all institutions if superadmin" do
      super_user = User.make
      super_institution = user.create Institution.make_unsaved
      super_device = Device.make institution_id: super_institution.id
      super_user.grant_superadmin_policy

      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: super_device)])

      refresh_index

      result = TestResultQuery.for({"condition" => 'mtb'}, super_user).execute
      expect(result['total_count']).to eq(2)
    end
  end

  context "query adapting" do
    it "should include institution name, device name, and site name in the tests" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      refresh_index

      result = TestResultQuery.for({"condition" => 'mtb'}, user).execute


      expect(result['tests'].first['institution']['name']).to eq(institution.name)
      expect(result['tests'].first['device']['name']).to eq(user_device.name)
      expect(result['tests'].first['site']['name']).to eq(site.name)
    end

    it "should include names if there is no site" do
      site
      device = Device.make institution_id: institution.id, site: nil
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: device)])
      refresh_index

      result = TestResultQuery.for({"condition" => 'mtb'}, user).execute

      expect(result['tests'].first['institution']['name']).to eq(institution.name)
      expect(result['tests'].first['device']['name']).to eq(device.name)
      expect(result['tests'].first['site']['name']).to eq(nil)
    end

    it "should include the updated institution name, device name, and site name in the tests" do
      TestResult.create_and_index(core_fields: core_fields, device_messages:[DeviceMessage.make(device: user_device)])
      refresh_index

      institution.name = 'abc'
      institution.save!
      result = TestResultQuery.for({"condition" => 'mtb'}, user).execute


      expect(result['tests'].first['institution']['name']).to eq(institution.name)
      expect(result['tests'].first['device']['name']).to eq(user_device.name)
      expect(result['tests'].first['site']['name']).to eq(site.name)
    end

  end
end
