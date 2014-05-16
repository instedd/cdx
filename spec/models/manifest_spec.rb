require 'spec_helper'

describe Manifest do
  it "creates a device model named according to the manifest" do
    manifest = '{"device_models" : ["foo"]}'
    Manifest.create(definition: manifest)

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(manifest)
    DeviceModel.count.should eq(1)
    Manifest.first.device_models.first.name.should eq("foo")
  end

  it "updates it's version number" do
    Manifest.create(definition: '{"device_models" : ["foo"], "version" : 1}')

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = '{"device_models" : ["foo"], "version" : 2}'
    manifest.save!

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.version.should eq(2)
  end

  it "leaves no orphan model" do
    Manifest.create(definition: '{"device_models" : ["foo"], "version" : 1}')

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.destroy()
    Manifest.count.should eq(0)
    DeviceModel.count.should eq(0)

    Manifest.create(definition: '{"device_models" : ["foo"], "version" : 1}')
    Manifest.create(definition: '{"device_models" : ["bar"], "version" : 1}')

    Manifest.count.should eq(2)
    DeviceModel.count.should eq(2)
    Manifest.first.destroy()
    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)

    Manifest.first.device_models.first.should eq(DeviceModel.first)
  end
end
