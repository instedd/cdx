require 'spec_helper'

describe Api::EventsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump results: [result: :positive]}

  before(:each) {sign_in user}

  context "Locations" do
    let(:parent_location) {Location.make}
    let(:leaf_location1) {Location.make parent: parent_location}
    let(:leaf_location2) {Location.make parent: parent_location}
    let(:upper_leaf_location) {Location.make}

    let(:laboratory1) {Laboratory.make institution: institution, location_geoid: leaf_location1.id}
    let(:laboratory2) {Laboratory.make institution: institution, location_geoid: leaf_location2.id}
    let(:laboratory3) {Laboratory.make institution: institution, location_geoid: upper_leaf_location.id}

    it "should store the location id when the device is registered in only one laboratory" do
      device.laboratories = [laboratory1]
      device.save!
      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["location_id"].should eq(leaf_location1.geo_id)
      test["laboratory_id"].should eq(laboratory1.id)
      test["parent_locations"].sort.should eq([leaf_location1.geo_id, parent_location.geo_id].sort)
      test["location"]['admin_level_0'].should eq(parent_location.geo_id)
      test["location"]['admin_level_1'].should eq(leaf_location1.geo_id)
    end

    it "should store the parent location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory1, laboratory2]
      device.save!

      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["location_id"].should eq(parent_location.geo_id)
      test["laboratory_id"].should be_nil
      test["parent_locations"].should eq([parent_location.geo_id].sort)
      test["location"]['admin_level_0'].should eq(parent_location.geo_id)
    end

    it "should store the root location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory2, laboratory3]
      device.save!

      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["location_id"].should eq(nil)
      test["laboratory_id"].should be_nil
      test["parent_locations"].should eq([])
    end

    it "should store the root location id when the device is registered more than one laboratory with another tree order" do
      device.laboratories = [laboratory3, laboratory2]
      device.save!

      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["location_id"].should eq(nil)
      test["laboratory_id"].should be_nil
      test["parent_locations"].should eq([])
    end

    it "should store nil if no location was found" do
      device.laboratories = []
      device.save!

      post :create, data, device_id: device.uuid, authentication_token: device.plain_secret_key

      test = all_elasticsearch_tests_for(institution).first["_source"]
      test["location_id"].should be_nil
      test["laboratory_id"].should be_nil
      test["parent_locations"].should eq([])
      test["location"].should eq({})
    end

  end

end
