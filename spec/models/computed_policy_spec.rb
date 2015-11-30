require 'spec_helper'
require 'policy_spec_helper'

include Policy::Actions

describe ComputedPolicy do

  before(:each) { allow(Policy).to receive(:implicit).and_return(nil) }

  let!(:user) { User.make email: "user@example.com" }

  context "from superadmin" do

    let!(:device)  { Device.make }
    let!(:device2) { Device.make }

    let!(:superadmin) do
      User.make { |u| u.grant_superadmin_policy }
    end

    it "should create computed policy for single resource" do
      expect {
        grant superadmin, user, device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies(:reload).last.tap do |p|
        expect(p.user).to eq(user)
        expect(p.action).to eq(READ_DEVICE)
        expect(p.resource_type).to eq('device')
        expect(p.resource_id).to eq(device.id.to_s)
        expect(p.condition_institution_id).to be_nil
        expect(p.condition_site_id).to be_nil
      end
    end

    it "should create computed policy for all resources" do
      expect {
        grant superadmin, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies(:reload).last.tap do |p|
        expect(p.action).to eq(READ_DEVICE)
        expect(p.resource_type).to eq('device')
        expect(p.resource_id).to be_nil
      end
    end

    it "should create computed policy for multiple actions and resources" do
      expect {
        grant superadmin, user, [device, device2], [READ_DEVICE, UPDATE_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(4)

      [[READ_DEVICE, device.id],
       [READ_DEVICE, device2.id],
       [UPDATE_DEVICE, device.id],
       [UPDATE_DEVICE, device2.id]].each do |action, id|
        expect(user.computed_policies.where(action: action, resource_type: 'device', resource_id: id).first).not_to be_nil
      end
    end

    it "should not create computed policy for unrelated actions and resources" do
      expect {
        grant superadmin, user, [device, device.site], [READ_DEVICE, READ_SITE]
      }.to change(user.computed_policies(:reload), :count).by(2)
    end

    it "should add permissions from two policies" do
      expect {
        grant superadmin, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect {
        grant superadmin, user, Device, [UPDATE_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user.computed_policies.map(&:action)).to match([READ_DEVICE, UPDATE_DEVICE])
    end

    it "should grant permissions filtered by institution" do
      expect {
        grant superadmin, user, "device?institution=#{device.institution.id}", [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_institution_id).to eq(device.institution.id)
      end
    end

    it "should grant permissions filtered by site" do
      expect {
        grant superadmin, user, "device?site=#{device.site.id}", [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_site_id).to eq(device.site.prefix)
      end
    end

    it "should except a resource" do
      expect {
        grant superadmin, user, Device, [READ_DEVICE], except: [device]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user).to have(1).computed_policies
      p = user.computed_policies.first
      expect(p.resource_id).to be_nil

      expect(p).to have(1).exceptions
      expect(p.exceptions.first.resource_id).to eq(device.id.to_s)
    end

  end


  context "from regular user" do

    let!(:device)  { Device.make }
    let!(:device2) { Device.make }

    let!(:granter)  { User.make }
    let!(:granter2) { User.make }

    it "should create intersection from resources" do
      grant nil, granter, [device, device2], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(2)

      expect(user.computed_policies.map(&:resource_id)).to match_array([device.id, device2.id].map(&:to_s))
    end

    it "should create intersection from delegable resources" do
      grant nil, granter, [device],  [READ_DEVICE]
      grant nil, granter, [device2], [READ_DEVICE], delegable: false

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user.computed_policies.first.resource_id).to eq(device.id.to_s)
    end

    it "should create intersection from resources with conditions" do
      grant nil, granter, "device?institution=#{device.institution.id}", [READ_DEVICE]

      expect {
        grant granter, user, "device?site=#{device.site.id}", [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_site_id).to eq(device.site.prefix)
        expect(p.condition_institution_id).to eq(device.institution.id)
      end
    end

    it "should create intersection from actions" do
      grant nil, granter, [device], [READ_DEVICE, UPDATE_DEVICE]

      expect {
        grant granter, user, [device], '*'
      }.to change(user.computed_policies(:reload), :count).by(2)

      expect(user.computed_policies.map(&:action)).to match_array([READ_DEVICE, UPDATE_DEVICE])
    end

    it "should compact identical rules in policies" do
      grant nil, granter,  [device], [READ_DEVICE, UPDATE_DEVICE]
      grant nil, granter2, [device], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect {
        grant granter2, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(0)
    end

    it "should compact undelegable with delegable rules" do
      grant nil, granter,  [device], [READ_DEVICE]
      grant nil, granter2, [device], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE], delegable: true
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect {
        grant granter2, user, Device, [READ_DEVICE], delegable: false
      }.to change(user.computed_policies(:reload), :count).by(0)

      expect(user.computed_policies(:reload).first.delegable).to be_truthy
    end

    it "should not compact undelegable with delegable rules on different resources" do
      grant nil, granter,  [device], [READ_DEVICE]
      grant nil, granter2, [device, device2], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE], delegable: true
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect {
        grant granter2, user, Device, [READ_DEVICE], delegable: false
      }.to change(user.computed_policies(:reload), :count).by(1)

      p1, p2 = user.computed_policies(:reload).order(:id).all

      expect(p1.resource_id).to eq(device.id.to_s)
      expect(p1.delegable).to be_truthy

      expect(p2.resource_id).to eq(device2.id.to_s)
      expect(p2.delegable).to be_falsey
    end

    it "should compact subsumed rules in policies" do
      grant nil, granter,  Device, [READ_DEVICE]
      grant nil, granter2, Device, [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect {
        grant granter2, user, device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(0)

      user.computed_policies.first.tap do |p|
        expect(p.resource_id).to be_nil
        expect(p.resource_type).to eq('device')
      end
    end

    it "should not compact rules in policies if they are different due to exceptions" do
      grant nil, granter,  Device, [READ_DEVICE]
      grant nil, granter2, Device, [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE], except: device
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect {
        grant granter2, user, device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)
    end

    it "should join exceptions when granting permissions" do
      grant nil, granter, Device, [READ_DEVICE], except: [device]

      expect {
        grant granter, user, Device, [READ_DEVICE], except: [device2]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user).to have(1).computed_policies
      expect(user.computed_policies.first).to have(2).exceptions
      exceptions = user.computed_policies.first.exceptions

      expect(exceptions.map(&:resource_id)).to match_array([device.id.to_s, device2.id.to_s])
    end

    it "should not join exceptions when not applicable" do
      grant nil, granter, [Site, Device], [READ_SITE, READ_DEVICE]

      expect {
        grant granter, user, [Site, Device], [READ_SITE, READ_DEVICE], except: [device]
      }.to change(user.computed_policies, :count).by(2)

      site_policies = user.computed_policies.where(resource_type: "site")
      expect(site_policies.size).to eq(1)
      expect(site_policies.map(&:exceptions).flatten).to be_empty

      device_policies = user.computed_policies.where(resource_type: 'device')
      expect(device_policies.size).to eq(1)

      device_policies.each do |p|
        expect(p).to have(1).exceptions
        expect(p.exceptions.first.resource_id).to eq(device.id.to_s)
      end
    end

  end

  context "recursively" do

    let!(:device)  { Device.make }
    let!(:device2) { Device.make }

    let!(:granter)  { User.make }
    let!(:granter2) { User.make }
    let!(:granter3) { User.make }

    it "should recompute policies" do
      i1 = granter.institutions.make
      i2 = granter2.institutions.make

      expect {
        grant granter2, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user.computed_policies.first.condition_institution_id).to eq(i2.id)
      expect(user.computed_policies.first.resource_id).to be_nil

      expect {
        grant granter, granter2, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user.computed_policies(:reload).map(&:condition_institution_id)).to match_array([i1.id, i2.id])
    end

    it "should recompute policies when a policy is removed" do
      i1 = granter.institutions.make
      i2 = granter2.institutions.make

      policies = []

      expect {
        policies << grant(granter, granter2, Device, [READ_DEVICE])
        policies << grant(granter2, user, Device, [READ_DEVICE])
      }.to change(user.computed_policies(:reload), :count).by(2)

      expect(granter.computed_policies.on("device").map(&:condition_institution_id)).to  match_array([i1.id])
      expect(granter2.computed_policies.on("device").map(&:condition_institution_id)).to match_array([i1.id, i2.id])
      expect(user.computed_policies.on("device").map(&:condition_institution_id)).to     match_array([i1.id, i2.id])

      expect {
        policies.first.reload.destroy!
      }.to change(user.computed_policies(:reload), :count).by(-1)

      expect(user.computed_policies(:reload).map(&:condition_institution_id)).to match_array([i2.id])
    end

    it "should recompute policies when an institution is destroyed (#453)" do
      old_computed_policies = granter.computed_policies.to_a

      i1 = granter.institutions.make
      i1.destroy

      granter.reload
      expect(granter.computed_policies.to_a).to eq(old_computed_policies)
    end

    it "should support a loop of policies" do
      i1 = granter.institutions.make
      i2 = granter2.institutions.make
      i3 = granter3.institutions.make

      grant(granter, granter2, Device, [READ_DEVICE])
      grant(granter2, granter3, Device, [READ_DEVICE])
      grant(granter3, granter, Device, [READ_DEVICE])

      [granter, granter2, granter3].each do |g|
        expect(g.reload.computed_policies.on("device").map(&:condition_institution_id)).to match_array([i1.id, i2.id, i3.id])
      end
    end

  end


  context "condition resources" do

    let!(:institution_i1) { Institution.make }
    let!(:institution_i2) { Institution.make }

    let!(:site_i1_l1) { institution_i1.sites.make }
    let!(:site_i1_l2) { institution_i1.sites.make }
    let!(:site_i2_l1) { institution_i2.sites.make }
    let!(:site_i2_l2) { institution_i2.sites.make }

    let!(:device_i1_l1_d1) { site_i1_l1.devices.make }
    let!(:device_i1_l1_d2) { site_i1_l1.devices.make }
    let!(:device_i1_l2_d1) { site_i1_l2.devices.make }
    let!(:device_i1_l2_d2) { site_i1_l2.devices.make }
    let!(:device_i2_l1_d1) { site_i2_l1.devices.make }
    let!(:device_i2_l1_d2) { site_i2_l1.devices.make }
    let!(:device_i2_l2_d1) { site_i2_l2.devices.make }
    let!(:device_i2_l2_d2) { site_i2_l2.devices.make }

    def condition_resources(action=QUERY_TEST, resource=TestResult, u=nil)
      resources = ComputedPolicy.condition_resources_for(action, resource, u || user)
      [:institution, :site, :device].map {|key| resources[key]}
    end

    it "should return empty if no policies" do
      institutions, sites, devices = condition_resources
      expect(institutions).to be_empty
      expect(sites).to be_empty
      expect(devices).to      be_empty
    end

    it "should return all institution assets when user has a policy by institution" do
      grant nil, user, {:test_result => institution_i1}, QUERY_TEST
      institutions, sites, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to contain_exactly(site_i1_l1, site_i1_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2)
    end

    it "should return all site assets when user has a policy by site" do
      grant nil, user, {:test_result => site_i1_l1}, QUERY_TEST
      institutions, sites, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to contain_exactly(site_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2)
    end

    it "should return a device when user has a policy by device" do
      grant nil, user, {:test_result => device_i1_l1_d1}, QUERY_TEST
      institutions, sites, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to contain_exactly(site_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1)
    end

    it "should return all relevant assets when has multiple policies" do
      grant nil, user, {:test_result => institution_i1},   QUERY_TEST
      grant nil, user, {:test_result => site_i2_l1}, QUERY_TEST
      grant nil, user, {:test_result => device_i2_l2_d1},  QUERY_TEST
      institutions, sites, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1, institution_i2)
      expect(sites).to contain_exactly(site_i1_l1, site_i1_l2, site_i2_l1, site_i2_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2, device_i2_l1_d1, device_i2_l1_d2, device_i2_l2_d1)
    end

    it "should only return resources for the matching action" do
      grant nil, user, {:device => site_i1_l1}, READ_DEVICE
      grant nil, user, {:device => site_i1_l2}, UPDATE_DEVICE
      institutions, sites, devices = condition_resources(READ_DEVICE, Device)

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to        contain_exactly(site_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2)
    end

    it "should return devices with no sites if policy is by institution" do
      device_i3_s0_d1 = Device.make(institution: Institution.make, site: nil)
      device_i4_s0_d1 = Device.make(institution: Institution.make, site: nil)
      expect(device_i3_s0_d1.site).to be_nil

      grant nil, user, {:device => device_i3_s0_d1.institution}, READ_DEVICE
      institutions, sites, devices = condition_resources(READ_DEVICE, Device)

      expect(institutions).to contain_exactly(device_i3_s0_d1.institution)
      expect(sites).to        be_empty
      expect(devices).to      contain_exactly(device_i3_s0_d1)
    end

    it "should return devices with no sites if policy is by institution" do
      device_i1_s0_d1 = Device.make(institution: institution_i1, site: nil)
      expect(device_i1_s0_d1.site).to be_nil

      grant nil, user, {:device => institution_i1}, READ_DEVICE
      institutions, sites, devices = condition_resources(READ_DEVICE, Device)

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to        contain_exactly(site_i1_l1, site_i1_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2, device_i1_s0_d1)
    end

    it "should not return devices with no sites if policy is by sites" do
      device_i1_s0_d1 = Device.make(institution: institution_i1, site: nil)
      expect(device_i1_s0_d1.site).to be_nil

      grant nil, user, {:device => site_i1_l1}, READ_DEVICE
      grant nil, user, {:device => site_i1_l2}, READ_DEVICE
      institutions, sites, devices = condition_resources(READ_DEVICE, Device)

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to        contain_exactly(site_i1_l1, site_i1_l2)
      expect(devices).not_to  include(device_i1_s0_d1)
    end

    it "should not return resources in exceptions" do
      grant nil, user, {:test_result => site_i1_l1}, QUERY_TEST, except: [{test_result: device_i1_l1_d2}]
      institutions, sites, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to contain_exactly(site_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1)
    end

    it "should return resources in exceptions if allowed in another policy" do
      grant nil, user, {:test_result => site_i1_l1}, QUERY_TEST, except: [{test_result: device_i1_l1_d2}]
      grant nil, user, {:test_result => institution_i1},   QUERY_TEST
      institutions, sites, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(sites).to contain_exactly(site_i1_l1, site_i1_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2)
    end

    it "should not return any resource if exception contains granted" do
      grant nil, user, {:test_result => device_i1_l1_d1}, QUERY_TEST, except: [{test_result: site_i1_l1}]
      institutions, sites, devices = condition_resources

      expect(institutions).to be_empty
      expect(sites).to be_empty
      expect(devices).to      be_empty
    end

    it "should return everything if user is superadmin" do
      user.grant_superadmin_policy
      institutions, sites, devices = condition_resources

      expect(institutions).to match_array(Institution.all)
      expect(sites).to match_array(Site.all)
      expect(devices).to      match_array(Device.all)
    end

    it "should return all resources if allowed in an implicit policy" do
      grant nil, user, TestResult, QUERY_TEST
      grant nil, user, {:test_result => institution_i1}, "*"
      institutions, sites, devices = condition_resources

      expect(institutions).to match_array(Institution.all)
      expect(sites).to match_array(Site.all)
      expect(devices).to      match_array(Device.all)
    end

  end

  context "sites" do
    let!(:site1) { Site.make }
    let!(:site11) { Site.make :child, parent: site1 }
    let!(:site111) { Site.make :child, parent: site11 }

    let!(:device1) { Device.make site_id: site1.id }
    let!(:device11) { Device.make site_id: site11.id }

    let!(:granter)  { User.make }
    let!(:granter2) { User.make }

    it "grants access to same site" do
      grant nil, granter, site1, [READ_SITE]

      expect {
        grant granter, granter2, site1, READ_SITE
      }.to change(granter2.computed_policies(:reload), :count).by(1)

      expect(granter2).to have(1).computed_policies
      p = granter2.computed_policies.first
      expect(p.resource_id).to eq(site1.prefix)
    end

    it "grants access to subsite" do
      grant nil, granter, site1, [READ_SITE]

      expect {
        grant granter, granter2, site11, READ_SITE
      }.to change(granter2.computed_policies(:reload), :count).by(1)

      expect(granter2).to have(1).computed_policies
      p = granter2.computed_policies.first
      expect(p.resource_id).to eq(site11.prefix)
    end

    it "grants access to subsubsite" do
      grant nil, granter, site1, [READ_SITE]

      expect {
        grant granter, granter2, site111, READ_SITE
      }.to change(granter2.computed_policies(:reload), :count).by(1)

      expect(granter2).to have(1).computed_policies
      p = granter2.computed_policies.first
      expect(p.resource_id).to eq(site111.prefix)
    end

    it "interesects no site condition with site condition" do
      grant nil, granter, device11, [READ_DEVICE]

      expect {
        grant granter, granter2, "device?site=#{device11.site.id}", [READ_DEVICE]
      }.to change(granter2.computed_policies(:reload), :count).by(1)

      expect(granter2).to have(1).computed_policies
      p = granter2.computed_policies.first
      expect(p.condition_site_id).to eq(site11.prefix)
    end

    it "interesects two site conditions" do
      grant nil, granter, "device?site=#{device1.site.id}", [READ_DEVICE]

      expect {
        grant granter, granter2, "device?site=#{device11.site.id}", [READ_DEVICE]
      }.to change(granter2.computed_policies(:reload), :count).by(1)

      expect(granter2).to have(1).computed_policies
      p = granter2.computed_policies.first
      expect(p.condition_site_id).to eq(site11.prefix)
    end
  end

  context "authorised users" do

    let!(:institution_i1) { Institution.make(user: nil) }
    let!(:institution_i2) { Institution.make(user: nil) }

    let!(:site_i1_l1) { institution_i1.sites.make }
    let!(:site_i1_l2) { institution_i1.sites.make }
    let!(:site_i2_l1) { institution_i2.sites.make }
    let!(:site_i2_l2) { institution_i2.sites.make }

    let!(:device_i1_l1_d1) { site_i1_l1.devices.make }
    let!(:device_i1_l1_d2) { site_i1_l1.devices.make }
    let!(:device_i1_l2_d1) { site_i1_l2.devices.make }
    let!(:device_i1_l2_d2) { site_i1_l2.devices.make }
    let!(:device_i2_l1_d1) { site_i2_l1.devices.make }
    let!(:device_i2_l1_d2) { site_i2_l1.devices.make }
    let!(:device_i2_l2_d1) { site_i2_l2.devices.make }
    let!(:device_i2_l2_d2) { site_i2_l2.devices.make }

    let!(:user2) { User.make email: "user2@example.com" }
    let!(:user3) { User.make email: "user3@example.com" }

    def authorized_users(action=[READ_DEVICE], resource=nil)
      ComputedPolicy.authorized_users(action, resource || device_i1_l1_d1)
    end

    context "when querying by a single resource" do

      it "should return users authorised by id" do

        grant nil, user,  device_i1_l1_d1, [READ_DEVICE]
        grant nil, user2, device_i1_l1_d1, [READ_DEVICE]
        grant nil, user3, device_i1_l1_d2, [READ_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user, user2)
      end

      it "should return users authorised by site scope" do
        grant nil, user,  {device: site_i1_l1}, [READ_DEVICE]
        grant nil, user2, {device: site_i1_l1}, [READ_DEVICE]
        grant nil, user3, {device: site_i1_l2}, [READ_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user, user2)
      end

      it "should return users authorised by institution scope" do
        grant nil, user,  {device: institution_i1}, [READ_DEVICE]
        grant nil, user2, {device: institution_i1}, [READ_DEVICE]
        grant nil, user3, {device: institution_i2}, [READ_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user, user2)
      end

      it "should not return users with exception by id" do
        grant nil, user,  {device: site_i1_l1}, [READ_DEVICE], except: [device_i1_l1_d1]
        grant nil, user2, {device: site_i1_l1}, [READ_DEVICE], except: [device_i1_l1_d2]
        grant nil, user3, {device: site_i1_l2}, [READ_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user2)
      end

      it "should not return users with exception by site" do
        grant nil, user,  {device: institution_i1}, [READ_DEVICE], except: [{device: site_i1_l1}]
        grant nil, user2, {device: institution_i1}, [READ_DEVICE], except: [{device: site_i1_l2}]
        grant nil, user3, {device: institution_i2}, [READ_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user2)
      end

      it "should not return users with different action" do
        grant nil, user,  device_i1_l1_d1, [READ_DEVICE]
        grant nil, user2, device_i1_l1_d1, [READ_DEVICE]
        grant nil, user3, device_i1_l1_d1, [UPDATE_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user, user2)
      end

      it "should return users with all actions for the resource" do
        grant nil, user,  device_i1_l1_d1, [READ_DEVICE]
        grant nil, user2, device_i1_l1_d1, "*"
        grant nil, user3, device_i1_l1_d1, [UPDATE_DEVICE]

        expect(authorized_users(READ_DEVICE, device_i1_l1_d1)).to contain_exactly(user, user2)
      end

    end

    context "when querying by a class" do

      it "should return users with access to any resource" do
        grant nil, user,  device_i1_l1_d1,      [READ_DEVICE]
        grant nil, user2, {device: site_i1_l1}, [READ_DEVICE]
        grant nil, user3, site_i1_l1,           [READ_SITE]

        expect(authorized_users(READ_DEVICE, Device)).to contain_exactly(user, user2)
      end

    end

  end

  context "roles" do

    let!(:device)  { Device.make }

    let!(:superadmin) do
      User.make { |u| u.grant_superadmin_policy }
    end

    it "should create computed policy for single resource" do
      policy = grant nil, nil, device, [READ_DEVICE]
      role = Role.make institution: device.institution, policy: policy

      expect {
        role.users << user
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies(:reload).last.tap do |p|
        expect(p.user).to eq(user)
        expect(p.action).to eq(READ_DEVICE)
        expect(p.resource_type).to eq('device')
        expect(p.resource_id).to eq(device.id.to_s)
        expect(p.condition_institution_id).to be_nil
        expect(p.condition_site_id).to be_nil
      end
    end
  end
end
