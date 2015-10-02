require 'spec_helper'
require 'policy_spec_helper'

include Policy::Actions

describe ComputedPolicy do

  before(:each) { allow(Policy).to receive(:implicit).and_return(nil) }

  let!(:user) { User.make }

  let!(:device)  { Device.make }
  let!(:device2) { Device.make }

  context "from superadmin" do

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
        expect(p.resource_id).to eq(device.id)
        expect(p.condition_institution_id).to be_nil
        expect(p.condition_laboratory_id).to be_nil
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
        grant superadmin, user, [device, device.laboratory], [READ_DEVICE, READ_LABORATORY]
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

    it "should grant permissions filtered by laboratory" do
      expect {
        grant superadmin, user, "device?laboratory=#{device.laboratory.id}", [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_laboratory_id).to eq(device.laboratory.id)
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
      expect(p.exceptions.first.resource_id).to eq(device.id)
    end

  end


  context "from regular user" do

    let!(:granter)  { User.make }
    let!(:granter2) { User.make }

    it "should create intersection from resources" do
      grant nil, granter, [device, device2], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(2)

      expect(user.computed_policies.map(&:resource_id)).to match_array([device.id, device2.id])
    end

    it "should create intersection from delegable resources" do
      grant nil, granter, [device],  [READ_DEVICE]
      grant nil, granter, [device2], [READ_DEVICE], delegable: false

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user.computed_policies.first.resource_id).to eq(device.id)
    end

    it "should create intersection from resources with conditions" do
      grant nil, granter, "device?institution=#{device.institution.id}", [READ_DEVICE]

      expect {
        grant granter, user, "device?laboratory=#{device.laboratory.id}", [READ_DEVICE]
      }.to change(user.computed_policies(:reload), :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_laboratory_id).to eq(device.laboratory.id)
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

      expect(p1.resource_id).to eq(device.id)
      expect(p1.delegable).to be_truthy

      expect(p2.resource_id).to eq(device2.id)
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

    it "should join exceptions when granting permissions" do
      grant nil, granter, Device, [READ_DEVICE], except: [device]

      expect {
        grant granter, user, Device, [READ_DEVICE], except: [device2]
      }.to change(user.computed_policies(:reload), :count).by(1)

      expect(user).to have(1).computed_policies
      expect(user.computed_policies.first).to have(2).exceptions
      exceptions = user.computed_policies.first.exceptions

      expect(exceptions.map(&:resource_id)).to match_array([device.id, device2.id])
    end

    it "should not join exceptions when not applicable" do
      grant nil, granter, [Laboratory, Device], [READ_LABORATORY, READ_DEVICE]

      expect {
        grant granter, user, [Laboratory, Device], [READ_LABORATORY, READ_DEVICE], except: [device]
      }.to change(user.computed_policies, :count).by(2)

      lab_policies = user.computed_policies.where(resource_type: "laboratory")
      expect(lab_policies.size).to eq(1)
      expect(lab_policies.map(&:exceptions).flatten).to be_empty

      device_policies = user.computed_policies.where(resource_type: 'device')
      expect(device_policies.size).to eq(1)

      device_policies.each do |p|
        expect(p).to have(1).exceptions
        expect(p.exceptions.first.resource_id).to eq(device.id)
      end
    end

  end

  context "recursively" do

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

    let!(:laboratory_i1_l1) { institution_i1.laboratories.make }
    let!(:laboratory_i1_l2) { institution_i1.laboratories.make }
    let!(:laboratory_i2_l1) { institution_i2.laboratories.make }
    let!(:laboratory_i2_l2) { institution_i2.laboratories.make }

    let!(:device_i1_l1_d1) { laboratory_i1_l1.devices.make }
    let!(:device_i1_l1_d2) { laboratory_i1_l1.devices.make }
    let!(:device_i1_l2_d1) { laboratory_i1_l2.devices.make }
    let!(:device_i1_l2_d2) { laboratory_i1_l2.devices.make }
    let!(:device_i2_l1_d1) { laboratory_i2_l1.devices.make }
    let!(:device_i2_l1_d2) { laboratory_i2_l1.devices.make }
    let!(:device_i2_l2_d1) { laboratory_i2_l2.devices.make }
    let!(:device_i2_l2_d2) { laboratory_i2_l2.devices.make }

    def condition_resources(action=QUERY_TEST, resource=TestResult, u=nil)
      resources = ComputedPolicy.condition_resources_for(action, resource, u || user)
      [:institution, :laboratory, :device].map {|key| resources[key]}
    end

    it "should return empty if no policies" do
      institutions, laboratories, devices = condition_resources
      expect(institutions).to be_empty
      expect(laboratories).to be_empty
      expect(devices).to      be_empty
    end

    it "should return all institution assets when user has a policy by institution" do
      grant nil, user, {:test_result => institution_i1}, QUERY_TEST
      institutions, laboratories, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(laboratories).to contain_exactly(laboratory_i1_l1, laboratory_i1_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2)
    end

    it "should return all laboratory assets when user has a policy by lab" do
      grant nil, user, {:test_result => laboratory_i1_l1}, QUERY_TEST
      institutions, laboratories, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(laboratories).to contain_exactly(laboratory_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2)
    end

    it "should return a device when user has a policy by device" do
      grant nil, user, {:test_result => device_i1_l1_d1}, QUERY_TEST
      institutions, laboratories, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(laboratories).to contain_exactly(laboratory_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1)
    end

    it "should return all relevant assets when has multiple policies" do
      grant nil, user, {:test_result => institution_i1},   QUERY_TEST
      grant nil, user, {:test_result => laboratory_i2_l1}, QUERY_TEST
      grant nil, user, {:test_result => device_i2_l2_d1},  QUERY_TEST
      institutions, laboratories, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1, institution_i2)
      expect(laboratories).to contain_exactly(laboratory_i1_l1, laboratory_i1_l2, laboratory_i2_l1, laboratory_i2_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2, device_i2_l1_d1, device_i2_l1_d2, device_i2_l2_d1)
    end

    it "should only return resources for the matching action" do
      grant nil, user, {:device => laboratory_i1_l1}, READ_DEVICE
      grant nil, user, {:device => laboratory_i1_l2}, UPDATE_DEVICE
      institutions, laboratories, devices = condition_resources(READ_DEVICE, Device)

      expect(institutions).to contain_exactly(institution_i1)
      expect(laboratories).to contain_exactly(laboratory_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2)
    end

    it "should not return resources in exceptions" do
      grant nil, user, {:test_result => laboratory_i1_l1}, QUERY_TEST, except: [{test_result: device_i1_l1_d2}]
      institutions, laboratories, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(laboratories).to contain_exactly(laboratory_i1_l1)
      expect(devices).to      contain_exactly(device_i1_l1_d1)
    end

    it "should return resources in exceptions if allowed in another policy" do
      grant nil, user, {:test_result => laboratory_i1_l1}, QUERY_TEST, except: [{test_result: device_i1_l1_d2}]
      grant nil, user, {:test_result => institution_i1},   QUERY_TEST
      institutions, laboratories, devices = condition_resources

      expect(institutions).to contain_exactly(institution_i1)
      expect(laboratories).to contain_exactly(laboratory_i1_l1, laboratory_i1_l2)
      expect(devices).to      contain_exactly(device_i1_l1_d1, device_i1_l1_d2, device_i1_l2_d1, device_i1_l2_d2)
    end

    it "should not return any resource if exception contains granted" do
      grant nil, user, {:test_result => device_i1_l1_d1}, QUERY_TEST, except: [{test_result: laboratory_i1_l1}]
      institutions, laboratories, devices = condition_resources

      expect(institutions).to be_empty
      expect(laboratories).to be_empty
      expect(devices).to      be_empty
    end

  end

end
