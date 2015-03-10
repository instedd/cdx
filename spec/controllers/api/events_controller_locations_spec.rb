require 'spec_helper'

describe Api::EventsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump results: [result: :positive]}
  before(:each) {sign_in user}

  def get_updates(options, body="")
    fresh_client_for institution.elasticsearch_index_name
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["events"]
  end

  context "Locations" do
    let(:root_location) {Location.create_default}
    let(:parent_location) {Location.make parent: root_location}
    let(:leaf_location1) {Location.make parent: parent_location}
    let(:leaf_location2) {Location.make parent: parent_location}
    let(:upper_leaf_location) {Location.make parent: root_location}
    let(:laboratory1) {Laboratory.make institution: institution, location: leaf_location1}
    let(:laboratory2) {Laboratory.make institution: institution, location: leaf_location2}
    let(:laboratory3) {Laboratory.make institution: institution, location: upper_leaf_location}

    it "should store the location id when the device is registered in only one laboratory" do
      device.laboratories = [laboratory1]
      device.save!
      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["location_id"].should eq(leaf_location1.geo_id)
      event["laboratory_id"].should eq(laboratory1.id)
      event["parent_locations"].sort.should eq([leaf_location1.geo_id, parent_location.geo_id, root_location.geo_id].sort)
      event["location"]['admin_level_0'].should eq(root_location.geo_id)
      event["location"]['admin_level_1'].should eq(parent_location.geo_id)
      event["location"]['admin_level_2'].should eq(leaf_location1.geo_id)
    end

    it "should store the parent location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory1, laboratory2]
      device.save!

      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["location_id"].should eq(parent_location.geo_id)
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([root_location.geo_id, parent_location.geo_id].sort)
      event["location"]['admin_level_0'].should eq(root_location.geo_id)
      event["location"]['admin_level_1'].should eq(parent_location.geo_id)
    end

    it "should store the root location id when the device is registered more than one laboratory" do
      device.laboratories = [laboratory2, laboratory3]
      device.save!

      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["location_id"].should eq(root_location.geo_id)
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([root_location.geo_id])
      event["location"]['admin_level_0'].should eq(root_location.geo_id)
    end

    it "should store the root location id when the device is registered more than one laboratory with another tree order" do
      device.laboratories = [laboratory3, laboratory2]
      device.save!

      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["location_id"].should eq(root_location.geo_id)
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([root_location.geo_id])
      event["location"]['admin_level_0'].should eq(root_location.geo_id)
    end

    it "should store nil if no location was found" do
      device.laboratories = []
      device.save!

      post :create, data, device_id: device.secret_key

      event = all_elasticsearch_events_for(institution).first["_source"]
      event["location_id"].should be_nil
      event["laboratory_id"].should be_nil
      event["parent_locations"].should eq([])
      event["location"].should eq({})
    end

    it "filters by location" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]
      post :create, (Oj.dump results:[condition: "flu_a"]), device_id: device1.secret_key
      post :create, (Oj.dump results:[condition: "flu_b"]), device_id: device2.secret_key
      post :create, (Oj.dump results:[condition: "mtb"]), device_id: device3.secret_key

      response = get_updates(location: leaf_location1.geo_id)

      response.first["results"].first["condition"].should eq("flu_a")

      response = get_updates(location: leaf_location2.geo_id)

      response.first["results"].first["condition"].should eq("flu_b")

      response = get_updates(location: parent_location.geo_id).sort_by do |event|
        event["results"].first["condition"]
      end

      response.size.should eq(2)
      response[0]["results"].first["condition"].should eq("flu_a")
      response[1]["results"].first["condition"].should eq("flu_b")

      response = get_updates(location: root_location.geo_id).sort_by do |event|
        event["results"].first["condition"]
      end

      response.size.should eq(3)
      response[0]["results"].first["condition"].should eq("flu_a")
      response[1]["results"].first["condition"].should eq("flu_b")
      response[2]["results"].first["condition"].should eq("mtb")
    end

    it "groups by administrative level" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]
      post :create, (Oj.dump results:[condition: "flu_a"]), device_id: device1.secret_key
      post :create, (Oj.dump results:[condition: "flu_b"]), device_id: device2.secret_key
      post :create, (Oj.dump results:[condition: "mtb"]), device_id: device3.secret_key

      response = get_updates(group_by: {admin_level: 1})
      response.should eq([
        {"location"=>parent_location.geo_id, "count"=>2},
        {"location"=>upper_leaf_location.geo_id, "count"=>1}
      ])

      response = get_updates(group_by: {admin_level: 0})

      response.should eq([
        {"location"=>root_location.geo_id, "count"=>3}
      ])
    end
  end

end
