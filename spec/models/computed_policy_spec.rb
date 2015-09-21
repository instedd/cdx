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
        expect(p.allow).to be_truthy
        expect(p.action).to eq(READ_DEVICE)
        expect(p.resource_type).to eq("Device")
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
        expect(p.resource_type).to eq("Device")
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
        expect(user.computed_policies.where(action: action, resource_type: "Device", resource_id: id).first).not_to be_nil
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
        grant superadmin, user, "cdxp:device?institution=#{device.institution.id}", [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_institution_id).to eq(device.institution.id)
      end
    end

    it "should grant permissions filtered by laboratory" do
      expect {
        grant superadmin, user, "cdxp:device?laboratory=#{device.laboratory.id}", [READ_DEVICE]
      }.to change(ComputedPolicy, :count).by(1)

      user.computed_policies.first.tap do |p|
        expect(p.condition_laboratory_id).to eq(device.laboratory.id)
      end
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

      expect(user.computed_policies.map(&:resource_id)).to match([device.id, device2.id])
    end

    it "should create intersection from resources with conditions" do
      grant nil, granter, "cdxp:device?institution=#{device.institution.id}", [READ_DEVICE]

      expect {
        grant granter, user, "cdxp:device?laboratory=#{device.laboratory.id}?", [READ_DEVICE]
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

      expect(user.computed_policies.map(&:action)).to match([READ_DEVICE, UPDATE_DEVICE])
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
        expect(p.resource_type).to eq("Device")
      end
    end

  end

end
