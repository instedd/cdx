require 'spec_helper'
require 'policy_spec_helper'

describe Policy do

  let(:user) { User.make }
  let(:institution) { user.create Institution.make_unsaved }

  context "Validations" do

    let!(:user2) { User.make }

    it "disallows policy creation if self-granted" do
      policy = Policy.make_unsaved
      policy.granter = user
      policy.user = user
      expect(policy.save).to eq(false)
    end

    it "disallows policy creation if granter is nil" do
      policy = Policy.make_unsaved
      policy.granter = nil
      expect(policy.save).to eq(false)
    end

    it "should not create policy with invalid resource" do
      expect {
        grant user, user2, "invalid", "*"
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not create policy with invalid resource string" do
      expect {
        grant user, user2, "institution|1", "*"
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not create policy with invalid resource condition" do
      expect {
        grant user, user2, "institution?site_id=1", "*"
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not create policy with invalid action" do
      expect {
        grant user, user2, "institution", "INVALID"
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not create policy with test result by id" do
      expect {
        grant user, user2, "testResult/1", "INVALID"
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'should not create policy with no resource' do
      expect {
        grant user, user2, [], "*"
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

  end

  context "Authorize" do

    let!(:user2) { User.make }

    let!(:institution2a) { user2.institutions.make }
    let!(:institution2b) { user2.institutions.make }
    let!(:institution2c) { user2.institutions.make }

    before(:each) do
      user; institution
      grant user2, user, [institution2a, institution2b], READ_INSTITUTION
    end

    it "should return a scope when queried over a class" do
      authorized = Policy.authorize READ_INSTITUTION, Institution, user
      expect(authorized).to be_kind_of(Institution::ActiveRecord_Relation)
      expect(authorized.to_a).to contain_exactly(institution, institution2a, institution2b)
    end

    it "should return an empty scope when queried over an unauthorized class" do
      authorized = Policy.authorize READ_INSTITUTION, Institution, User.make
      expect(authorized).to be_kind_of(Institution::ActiveRecord_Relation)
      expect(authorized.to_a).to be_empty
    end

    it "should return an instance when queried over an instance" do
      authorized = Policy.authorize READ_INSTITUTION, institution2b, user
      expect(authorized).to be_kind_of(Institution)
      expect(authorized).to eq(institution2b)
    end

    it "should return nil when queried over an unauthorized instance" do
      authorized = Policy.authorize READ_INSTITUTION, institution2c, user
      expect(authorized).to be_nil
    end

  end


  context "with complex grants" do

    let!(:site1) { institution.sites.make }
    let!(:site2) { institution.sites.make }

    let!(:other_institution) { Institution.make }
    let!(:other_site)  { other_institution.sites.make }
    let!(:other_device)      { other_site.devices.make }

    let!(:user2) { User.make }

    it "should be able to see all sites if granted a policy for all and another by id" do
      grant nil,  user2, Site,  READ_SITE
      grant user, user2, site1, '*'

      assert_can user2, Site, READ_SITE, [site1, site2, other_site]
    end

    it "should be able to see all sites minus exceptions if granted a policy for all and another by id" do
      grant nil,  user2, Site,  READ_SITE, except: other_site
      grant user, user2, site1, '*'

      assert_can user2, Site, READ_SITE, [site1, site2]
    end

    it "should be able to see all sites minus exceptions if granted a policy for all" do
      grant nil, user2, Site, READ_SITE, except: other_site

      assert_can user2, Site, READ_SITE, [site1, site2]
    end

    it "should be able to see all sites including exceptions if granted a policy for all and another covering exceptions" do
      grant nil,  user2, Site, READ_SITE, except: site1
      grant user, user2, Site, READ_SITE

      assert_can  user2, Site, READ_SITE, [site1, site2, other_site]
    end

    it "should be able to see all sites including exceptions if granted a policy for all and another covering exceptions with all actions" do
      grant nil,  user2, Site, READ_SITE, except: site1
      grant user, user2, Site, "*"

      assert_can  user2, Site, READ_SITE, [site1, site2, other_site]
    end

  end


  context "Institution" do
    context "Create" do
      it "allows creating institutions" do
        user2 = User.make

        assert_can user2, Institution, CREATE_INSTITUTION, []
      end

      it "doesn't allow to create institutions if single-tenant deploy" do
        Settings.single_tenant = true

        user2 = User.make

        assert_cannot user2, Institution, CREATE_INSTITUTION

        Settings.single_tenant = false
      end
    end

    context "Read" do
      it "doesn't allow a user to read his institutions without the implicit policy" do
        user.policies.destroy_all
        user.reload

        assert_cannot user, Institution, READ_INSTITUTION
      end

      it "allows a user to read only his institutions" do
        user2, institution2 = create_user_and_institution

        assert_can user, Institution, READ_INSTITUTION, [institution]
      end

      it "allows a user to read an institution" do
        user.policies.destroy_all
        user2, institution2 = create_user_and_institution
        grant user2, user, institution2, [READ_INSTITUTION]
        user.reload

        assert_can user, institution2, READ_INSTITUTION
      end

      it "allows a user to read all institutions" do
        user2, institution2 = create_user_and_institution

        grant user2, user, Institution, [READ_INSTITUTION]

        assert_can user, Institution, READ_INSTITUTION, [institution, institution2]
      end

      it "doesn't allow a user to read another institution" do
        user2, institution2 = create_user_and_institution
        institution3 = Institution.make(user: user2)

        grant user2.reload, user.reload, institution3, [READ_INSTITUTION]

        assert_cannot user, institution2, READ_INSTITUTION
      end

      it "allows a user to list an institution" do
        user2, institution2 = create_user_and_institution

        grant user2, user, institution2, [READ_INSTITUTION]

        assert_can user, Institution, READ_INSTITUTION, [institution, institution2]
      end

      it "allows reading all institutions if superadmin" do
        user2, institution2 = create_user_and_institution
        user.grant_superadmin_policy

        assert_can user, Institution, READ_INSTITUTION, [institution, institution2]
      end

      it "disallows read one institution if granter doesn't have a permission for it" do
        user2 = User.make
        user3, institution3 = create_user_and_institution

        policy = grant user3, user, institution3, READ_INSTITUTION
        grant user, user2, institution3, READ_INSTITUTION

        policy.reload.destroy!

        assert_cannot user2, institution3, READ_INSTITUTION
      end

      it "disallows read all institution if granter doesn't have a permission for it" do
        user; institution
        user2 = User.make
        user3, institution3 = create_user_and_institution
        grant user, user2, Institution, READ_INSTITUTION

        assert_can user2, Institution, READ_INSTITUTION, [institution]
      end

      it "disallows delegable" do
        user2 = User.make
        user3 = User.make

        policy = grant user, user2, institution, READ_INSTITUTION, delegable: true
        grant user2, user3, institution, READ_INSTITUTION, delegable: true

        policy.reload.definition = policy_definition(institution, READ_INSTITUTION, false)
        policy.save!

        assert_cannot user3, institution, READ_INSTITUTION
      end

      it "allows delegable with disallow from one branch" do
        user2 = User.make
        user3 = User.make
        user4 = User.make

        grant user, user2, institution, READ_INSTITUTION, delegable: false
        grant user, user3, institution, READ_INSTITUTION, delegable: true
        grant user3, user4, institution, READ_INSTITUTION, delegable: true

        assert_can user4, institution, READ_INSTITUTION
      end

      it "allows checking when there's a loop" do
        user2, institution2 = create_user_and_institution
        user3, institution3 = create_user_and_institution

        grant user2, user3, institution2, READ_INSTITUTION
        grant user3, user2, institution2, READ_INSTITUTION

        assert_cannot user2, institution3, READ_INSTITUTION
        assert_can user3, institution2, READ_INSTITUTION
      end

      it "disallow read if explicitly denied" do
        user2 = User.make

        grant user, user2, institution, READ_INSTITUTION, except: institution

        assert_cannot user2, institution, READ_INSTITUTION
      end

      it "allows reading all institutions except one" do
        institution2 = user.create Institution.make_unsaved
        institution3 = user.create Institution.make_unsaved

        user2 = User.make

        grant user, user2, Institution, READ_INSTITUTION, except: institution3

        assert_can user2, Institution, READ_INSTITUTION, [institution, institution2]
      end
    end

    context "Update" do
      it "allows a user to update his institution" do
        assert_can user, institution, UPDATE_INSTITUTION
      end

      it "doesn't allows a user to update an instiutiton he is not an owner of" do
        user2, institution2 = create_user_and_institution

        assert_cannot user, institution2, UPDATE_INSTITUTION
      end

      it "allows a user to update an institution" do
        user.policies.destroy_all
        user2, institution2 = create_user_and_institution
        grant user2, user, institution2, UPDATE_INSTITUTION
        user.reload

        assert_can user, institution2, UPDATE_INSTITUTION
      end
    end

    context "Delete" do
      it "allows a user to delete his institution" do
        assert_can user, institution, DELETE_INSTITUTION
      end

      it "allows a user to delete an institution" do
        user2, institution2 = create_user_and_institution

        grant user2, user, institution2, [DELETE_INSTITUTION]

        assert_can user, institution2, DELETE_INSTITUTION
      end
    end
  end

  context "Site" do
    context "Create" do
      it "disallows creating institution site" do
        user2 = User.make
        assert_cannot user2, institution, CREATE_INSTITUTION_SITE
      end

      it "allows creating institution site" do
        user2 = User.make

        grant user, user2, institution, CREATE_INSTITUTION_SITE

        assert_can user2, institution, CREATE_INSTITUTION_SITE
      end
    end

    context "Read" do
      it "disallows reading institution site" do
        site = institution.sites.make

        user2 = User.make
        assert_cannot user2, site, READ_SITE
      end

      it "allows reading self site" do
        site = institution.sites.make

        assert_can user, site, READ_SITE
      end

      it "allows reading self sites" do
        site = institution.sites.make

        assert_can user, institution.sites, READ_SITE
      end

      it "allows reading an specific site" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, site, READ_SITE

        assert_can user2, site, READ_SITE
      end

      it "allows reading other sites" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, READ_SITE

        assert_can user2, Site, READ_SITE, [site]
      end

      it "allows reading other sites" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, READ_SITE

        assert_can user2, institution.sites, READ_SITE, [site]
      end

      it "allows reading other site" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, READ_SITE

        assert_can user2, site, READ_SITE
      end

      it "allows reading other institution sites" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, "#{Site.resource_name}?institution=#{institution.id}", READ_SITE

        assert_can user2, Site, READ_SITE, [site]
        assert_can user2, institution.sites, READ_SITE, [site]
      end

      it "disallows reading other institution sites when id is other" do
        institution2 = user.create Institution.make_unsaved

        site = institution.sites.make
        user2 = User.make

        grant user, user2, "#{Site.resource_name}?institution=#{institution2.id}", READ_SITE

        assert_cannot user2, site, READ_SITE
      end
    end

    context "Update" do
      it "disallows updating other user's site" do
        site = institution.sites.make
        user2 = User.make

        assert_cannot user2, site, UPDATE_SITE
      end

      it "allows updating an specific site" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, site, UPDATE_SITE

        assert_can user2, site, UPDATE_SITE
      end

      it "allows updating other user's sites" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, UPDATE_SITE

        assert_can user2, Site, UPDATE_SITE, [site]
      end

      it "allows updating other user's site" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, UPDATE_SITE

        assert_can user2, site, UPDATE_SITE
      end
    end

    context "Delete" do
      it "disallows deleting other user's site" do
        site = institution.sites.make
        user2 = User.make

        assert_cannot user2, site, DELETE_SITE
      end

      it "allows deleting an specific site" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, site, DELETE_SITE

        assert_can user2, site, DELETE_SITE
      end

      it "allows deleting other user's sites" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, DELETE_SITE

        assert_can user2, Site, DELETE_SITE, [site]
      end

      it "allows deleting other user's site" do
        site = institution.sites.make
        user2 = User.make

        grant user, user2, Site, DELETE_SITE

        assert_can user2, site, DELETE_SITE
      end
    end

    context "with subsites" do
      let!(:site1) { Site.make }
      let!(:site11) { Site.make :child, parent: site1 }
      let!(:site111) { Site.make :child, parent: site11 }

      let!(:device1) { Device.make site_id: site1.id }
      let!(:device11) { Device.make site_id: site11.id }

      let!(:user2) { User.make }

      it "can't access sub-sites" do
        grant nil, user, site1, READ_SITE

        assert_can user, site1, READ_SITE
        assert_cannot user, site11, READ_SITE
        assert_cannot user, site111, READ_SITE
      end

      it "can access sub-sites when specified" do
        grant nil, user, site1, READ_SITE, include_subsites: true

        assert_can user, site1, READ_SITE
        assert_can user, site11, READ_SITE
        assert_can user, site111, READ_SITE
      end

      it "can access sub-sites related to another site" do
        grant nil, user, site1, READ_SITE
        grant user, user2, site11, READ_SITE


        assert_cannot user2, site1, READ_SITE
        assert_cannot user2, site11, READ_SITE
        assert_cannot user2, site111, READ_SITE
      end

      it "can access sub-sites related to another site" do
        grant nil, user, site1, READ_SITE, include_subsites: true
        grant user, user2, site11, READ_SITE

        assert_cannot user2, site1, READ_SITE
        assert_can user2, site11, READ_SITE
        assert_cannot user2, site111, READ_SITE
      end

      it "can't access parent site when granted access to children only" do
        grant nil, user, site1, READ_SITE, include_subsites: true
        grant user, user2, site11, READ_SITE, include_subsites: true

        assert_cannot user2, site1, READ_SITE
        assert_can user2, site11, READ_SITE
        assert_can user2, site111, READ_SITE
      end

      it "can't access sub-site with condition when granted a single site" do
        grant nil, user, "device?site=#{site1.id}", READ_DEVICE

        assert_can user, device1, READ_DEVICE
        assert_cannot user, device11, READ_DEVICE
      end

      it "can access sub-site with condition" do
        grant nil, user, "device?site=#{site1.id}", READ_DEVICE, include_subsites: true

        assert_can user, device1, READ_DEVICE
        assert_can user, device11, READ_DEVICE
      end
    end
  end

  context "Device Model" do
    context "Update" do
      it "should not allow to update by manufacturer admin if has no institution" do
        device_model = DeviceModel.make
        user.institutions.make(kind: :manufacturer)
        assert_cannot user, device_model, UPDATE_DEVICE_MODEL
      end
    end
  end

  context "Device" do
    context "Create" do
      it "disallows creating institution device" do
        user2 = User.make
        assert_cannot user2, institution, REGISTER_INSTITUTION_DEVICE
      end

      it "allows creating institution device" do
        user2 = User.make

        grant user, user2, institution, REGISTER_INSTITUTION_DEVICE

        assert_can user2, institution, REGISTER_INSTITUTION_DEVICE
      end
    end

    context "Read" do
      it "disallows reading institution device" do
        device = institution.devices.make

        user2 = User.make
        assert_cannot user2, device, READ_DEVICE
      end

      it "allows reading self device" do
        device = institution.devices.make

        assert_can user, device, READ_DEVICE
      end

      it "allows reading self devices" do
        device = institution.devices.make

        assert_can user, institution.devices, READ_DEVICE, [device]
      end

      it "allows reading an specific device" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, device, READ_DEVICE

        assert_can user2, device, READ_DEVICE
      end

      it "allows reading institution devices" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, Institution, "*"
        grant user, user2, Device, READ_DEVICE

        assert_can user2, institution.devices, READ_DEVICE, [device]
      end

      it "allows reading other devices" do
        device = institution.devices.make
        other_device = Device.make

        user2 = User.make

        grant user, user2, Device, READ_DEVICE
        assert_can user2, Device, READ_DEVICE, [device]
      end

      it "allows reading other device" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, Device, READ_DEVICE

        assert_can user2, device, READ_DEVICE
      end

      it "allows reading other institution devices" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, "#{Device.resource_name}?institution=#{institution.id}", READ_DEVICE

        assert_can user2, Device, READ_DEVICE, [device]
        assert_can user2, institution.devices, READ_DEVICE, [device]
      end

      it "disallows reading other institution devices when id is other" do
        institution2 = user.create Institution.make_unsaved

        device = institution.devices.make
        user2 = User.make

        grant user, user2, "#{Device.resource_name}?institution=#{institution2.id}", READ_DEVICE

        assert_cannot user2, device, READ_DEVICE
      end
    end

    context "Update" do
      it "disallows updating other user's device" do
        device = institution.devices.make
        user2 = User.make

        assert_cannot user2, device, UPDATE_DEVICE
      end

      it "allows updating an specific device" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, device, UPDATE_DEVICE

        assert_can user2, device, UPDATE_DEVICE
      end

      it "allows updating other user's devices" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, Device, UPDATE_DEVICE

        assert_can user2, Device, UPDATE_DEVICE, [device]
      end

      it "allows updating other user's device" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, Device, UPDATE_DEVICE

        assert_can user2, device, UPDATE_DEVICE
      end
    end

    context "Delete" do
      it "disallows deleting other user's device" do
        device = institution.devices.make
        user2 = User.make

        assert_cannot user2, device, DELETE_DEVICE
      end

      it "allows deleting an specific device" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, device, DELETE_DEVICE

        assert_can user2, device, DELETE_DEVICE
      end

      it "allows deleting other user's devices" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, Device, DELETE_DEVICE

        assert_can user2, Device, DELETE_DEVICE, [device]
      end

      it "allows deleting other user's device" do
        device = institution.devices.make
        user2 = User.make

        grant user, user2, Device, DELETE_DEVICE

        assert_can user2, device, DELETE_DEVICE
      end
    end
  end

  context "Test Result" do

    context "Query" do

      let!(:user2) { User.make }

      let!(:site)  { Site.make institution: institution }
      let!(:device)      { Device.make institution_id: institution.id, site: site }
      let!(:test_result) { TestResult.make device_messages: [DeviceMessage.make(device: device)]}

      let!(:institution2) { user.institutions.make }
      let!(:site2)  { Site.make institution: institution2 }
      let!(:device2)      { Device.make institution_id: institution2.id, site: site2 }
      let!(:test_result2) { TestResult.make device_messages: [DeviceMessage.make(device: device2)]}

      let!(:institution3) { user.institutions.make }
      let!(:site3) { Site.make institution: institution3 }
      let!(:device3) { Device.make institution_id: institution3.id, site: site3 }
      let!(:site3_1) { Site.make institution: institution3, parent_id: site3.id }
      let!(:device3_1) { Device.make institution_id: institution3.id, site: site3_1 }
      let!(:test_result3) { TestResult.make device_messages: [DeviceMessage.make(device: device3)]}
      let!(:test_result3_1) { TestResult.make device_messages: [DeviceMessage.make(device: device3_1)]}

      it "does not allow user to query test result" do
        assert_cannot user2, test_result, QUERY_TEST
      end

      it "returns an empty scope when not authorised" do
        actual = Policy.authorize QUERY_TEST, TestResult, user2
        expect(actual.to_a).to be_empty
      end

      it "allows to query test result by institution" do
        grant user, user2, {test_result: institution}, QUERY_TEST
        assert_can user2, test_result, QUERY_TEST
      end

      it "allows to query test result by site" do
        grant user, user2, {test_result: site}, QUERY_TEST
        assert_can user2, test_result, QUERY_TEST
      end

      it "allows to query test result by device" do
        grant user, user2, {test_result: device}, QUERY_TEST
        assert_can user2, test_result, QUERY_TEST
      end

      it "returns a scope with tests authorised by institution" do
        grant user, user2, {test_result: institution}, QUERY_TEST
        assert_can user2, TestResult, QUERY_TEST, [test_result]
      end

      it "returns a scope with tests authorised by site" do
        grant user, user2, {test_result: site}, QUERY_TEST
        assert_can user2, TestResult, QUERY_TEST, [test_result]
      end

      it "returns a scope with tests authorised by site and subsite" do
        grant user, user2, {test_result: site3}, QUERY_TEST
        assert_can user2, TestResult, QUERY_TEST, [test_result3, test_result3_1]
      end

      it "returns a scope with tests authorised by device" do
        grant user, user2, {test_result: device}, QUERY_TEST
        assert_can user2, TestResult, QUERY_TEST, [test_result]
      end

      it "returns a scope with tests authorised by multiple criteria" do
        grant user, user2, {test_result: institution}, QUERY_TEST
        grant user, user2, {test_result: site2}, QUERY_TEST
        assert_can user2, TestResult, QUERY_TEST, [test_result, test_result2]
      end

      it "returns a scope with all tests" do
        grant user, user2, TestResult, QUERY_TEST
        assert_can user2, TestResult, QUERY_TEST, [test_result, test_result2, test_result3, test_result3_1]
      end

      it "returns a scope with all tests minus exceptions" do
        grant user, user2, TestResult, QUERY_TEST, except: {test_result: site2}
        assert_can user2, TestResult, QUERY_TEST, [test_result, test_result3, test_result3_1]
      end

    end

  end

  def create_user_and_institution
    user = User.make
    institution = user.create Institution.make_unsaved
    [user, institution]
  end

end
