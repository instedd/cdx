require 'spec_helper'
require 'policy_spec_helper'

include Policy::Actions

describe ComputedPolicy do

  let!(:user)       { User.make(skip_implicit_policy: true) }

  let!(:device)      { Device.make }
  let!(:device2)     { Device.make }

  context "from superadmin" do

    let!(:superadmin) { User.make(skip_implicit_policy: true) { |u| u.grant_superadmin_policy }}

    it "should create computed policy for single resource" do
      expect {
        grant superadmin, user, device, [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      ComputedPolicy.last.tap do |p|
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
      }.to change(ComputedPolicy, :count).by(1)

      ComputedPolicy.last.tap do |p|
        expect(p.action).to eq(READ_DEVICE)
        expect(p.resource_type).to eq('device')
        expect(p.resource_id).to be_nil
      end
    end

    it "should create computed policy for multiple actions and resources" do
      expect {
        grant superadmin, user, [device, device2], [READ_DEVICE, UPDATE_DEVICE]
      }.to change(ComputedPolicy, :count).by(4)

      [[READ_DEVICE, device.id],
       [READ_DEVICE, device2.id],
       [UPDATE_DEVICE, device.id],
       [UPDATE_DEVICE, device2.id]].each do |action, id|
        expect(user.computed_policies.where(action: action, resource_type: 'device', resource_id: id).first).not_to be_nil
      end
    end

    it "should add permissions from two policies" do
      expect {
        grant superadmin, user, Device, [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      expect {
        grant superadmin, user, Device, [UPDATE_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      expect(user.computed_policies.map(&:action)).to match([READ_DEVICE, UPDATE_DEVICE])
    end

    it "should grant permissions filtered by institution" do
      expect {
        grant superadmin, user, "device?institution=#{device.institution.id}", [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_institution_id).to eq(device.institution.id)
      end
    end

    it "should grant permissions filtered by laboratory" do
      expect {
        grant superadmin, user, "device?laboratory=#{device.laboratory.id}", [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_laboratory_id).to eq(device.laboratory.id)
      end
    end

    it "should except a resource" do
      expect {
        grant superadmin, user, Device, [READ_DEVICE], except: [device]
      }.to change(ComputedPolicy, :count).by(1)

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
      }.to change(ComputedPolicy, :count).by(2)

      expect(user.computed_policies.map(&:resource_id)).to match_array([device.id, device2.id])
    end

    it "should create intersection from delegable resources" do
      grant nil, granter, [device],  [READ_DEVICE]
      grant nil, granter, [device2], [READ_DEVICE], delegable: false

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      expect(user.computed_policies.first.resource_id).to eq(device.id)
    end

    it "should create intersection from resources with conditions" do
      grant nil, granter, "device?institution=#{device.institution.id}", [READ_DEVICE]

      expect {
        grant granter, user, "device?laboratory=#{device.laboratory.id}", [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_laboratory_id).to eq(device.laboratory.id)
        expect(p.condition_institution_id).to eq(device.institution.id)
      end
    end

    it "should create intersection from actions" do
      grant nil, granter, [device], [READ_DEVICE, UPDATE_DEVICE]

      expect {
        grant granter, user, [device], '*'
      }.to change(ComputedPolicy, :count).by(2)

      expect(user.computed_policies.map(&:action)).to match_array([READ_DEVICE, UPDATE_DEVICE])
    end

    it "should compact identical rules in policies" do
      grant nil, granter,  [device], [READ_DEVICE, UPDATE_DEVICE]
      grant nil, granter2, [device], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      expect {
        grant granter2, user, Device, [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(0)
    end

    it "should compact undelegable with delegable rules" do
      grant nil, granter,  [device], [READ_DEVICE]
      grant nil, granter2, [device], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE], delegable: true
      }.to change(ComputedPolicy, :count).by(1)

      expect {
        grant granter2, user, Device, [READ_DEVICE], delegable: false
      }.to change(ComputedPolicy, :count).by(0)

      expect(user.reload.computed_policies.first.delegable).to be_truthy
    end

    it "should not compact undelegable with delegable rules on different resources" do
      grant nil, granter,  [device], [READ_DEVICE]
      grant nil, granter2, [device, device2], [READ_DEVICE]

      expect {
        grant granter, user, Device, [READ_DEVICE], delegable: true
      }.to change(ComputedPolicy, :count).by(1)

      expect {
        grant granter2, user, Device, [READ_DEVICE], delegable: false
      }.to change(ComputedPolicy, :count).by(1)

      p1, p2 = user.reload.computed_policies.order(:id).all

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
      }.to change(ComputedPolicy, :count).by(1)

      expect {
        grant granter2, user, device, [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(0)

      user.computed_policies.first.tap do |p|
        expect(p.resource_id).to be_nil
        expect(p.resource_type).to eq('device')
      end
    end

    it "should join exceptions when granting permissions" do
      grant nil, granter, Device, [READ_DEVICE], except: [device]

      expect {
        grant granter, user, Device, [READ_DEVICE], except: [device2]
      }.to change(ComputedPolicy, :count).by(1)

      expect(user).to have(1).computed_policies
      expect(user.computed_policies.first).to have(2).exceptions
      exceptions = user.computed_policies.first.exceptions

      expect(exceptions.map(&:resource_id)).to match_array([device.id, device2.id])
    end

    it "should not join exceptions when not applicable" do
      grant nil, granter, [Laboratory, Device], [READ_LABORATORY, READ_DEVICE]

      expect {
        grant granter, user, [Laboratory, Device], [READ_LABORATORY, READ_DEVICE], except: [device]
      }.to change(ComputedPolicy, :count).by(4)

      expect(user).to have(4).computed_policies

      lab_policies = user.computed_policies.where(resource_type: "laboratory")
      expect(lab_policies.size).to eq(2)
      expect(lab_policies.map(&:exceptions).flatten).to be_empty

      device_policies = user.computed_policies.where(resource_type: 'device')
      expect(device_policies.size).to eq(2)

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
      }.to change(user.computed_policies, :count).by(1)

      expect(user.computed_policies.first.condition_institution_id).to eq(i2.id)
      expect(user.computed_policies.first.resource_id).to be_nil

      expect {
        grant granter, granter2, Device, [READ_DEVICE]
      }.to change(user.computed_policies, :count).by(1)

      expect(user.computed_policies.map(&:condition_institution_id)).to match_array([i1.id, i2.id])
    end

    it "should recompute policies when a policy is removed" do
      i1 = granter.institutions.make
      i2 = granter2.institutions.make

      policies = []

      expect {
        policies << grant(granter, granter2, Device, [READ_DEVICE])
        policies << grant(granter2, user, Device, [READ_DEVICE])
      }.to change(user.computed_policies, :count).by(2)

      expect(granter.computed_policies.on("device").map(&:condition_institution_id)).to  match_array([i1.id])
      expect(granter2.computed_policies.on("device").map(&:condition_institution_id)).to match_array([i1.id, i2.id])
      expect(user.computed_policies.on("device").map(&:condition_institution_id)).to     match_array([i1.id, i2.id])

      expect {
        policies.first.reload.destroy!
      }.to change(user.computed_policies, :count).by(-1)

      expect(user.computed_policies.map(&:condition_institution_id)).to match_array([i2.id])
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

end
