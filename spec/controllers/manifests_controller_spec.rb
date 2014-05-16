require 'spec_helper'

describe ManifestsController do
  let(:current_user) { User.make }
  before(:each) { sign_in current_user }

  it "creates a device model named according to the manifest" do
    manifest = '{"device_models" : ["foo"]}'
    post :create, manifest: {definition: manifest}

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(manifest)
    DeviceModel.count.should eq(1)
    Manifest.first.device_models.first.name.should eq("foo")
  end

  it "updates it's version number" do
    post :create, manifest: {definition: '{"device_models" : ["foo"], "version" : 1}'}

    Manifest.first.version.should eq(1)

    put :update, id: Manifest.first.id, manifest: {definition: '{"device_models" : ["foo"], "version" : 2}'}

    Manifest.count.should eq(1)
    DeviceModel.count.should eq(1)
    Manifest.first.version.should eq(2)
  end
end
