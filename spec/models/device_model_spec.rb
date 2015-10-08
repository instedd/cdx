require 'spec_helper'

describe DeviceModel do

  context "deletion" do

    let!(:device_model) { DeviceModel.make(:unpublished, institution: Institution.make) }
    let!(:published_device_model) { DeviceModel.make }

    let(:site) { Site.make(institution: device_model.institution)}

    it "should delete a device model" do
      expect {
        device_model.destroy!
      }.to change(DeviceModel, :count).by(-1)
    end

    it "should not delete a published device model" do
      count_was = DeviceModel.count
      expect {
        published_device_model.destroy!
      }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(DeviceModel.count).to eq(count_was)
    end

    it "should not delete a device model with devices from other institutions" do
      count_was = DeviceModel.count

      device_model.set_published_at; device_model.save!
      Device.make(device_model: device_model)
      device_model.unset_published_at; device_model.save!

      expect {
        device_model.reload.destroy!
      }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(DeviceModel.count).to eq(count_was)
    end

    it "should delete institution devices in cascade" do
      device_model.devices.make(site: site)

      # We need the relation to materialise so we define the expectation over the same instance
      # that will be used during the before_destroy callback
      device = device_model.devices.to_a.first

      expect(device).to receive(:destroy_cascade!) { device.destroy! }

      expect {
        device_model.destroy!
      }.to change(DeviceModel, :count).by(-1)
    end

  end

end
