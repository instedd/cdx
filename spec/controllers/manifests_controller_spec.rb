require 'spec_helper'

describe ManifestsController do
  let(:current_user) { User.make }
  before(:each) { sign_in current_user }

  it "creates a device model named according to the manifest" do
    manifest = '{"device_models" : ["foo"] }'
    post :create, manifest: {definition: manifest}

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(manifest)
    DeviceModel.count.should eq(1)
    Manifest.first.device_models.first.name.should eq("foo")
  end
end
