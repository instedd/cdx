require 'spec_helper'

describe Api::TestsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}

  before(:each) {sign_in user}

  def get_updates(options, body="")
    fresh_client_for institution.elasticsearch_index_name
    response = get :index, body, options.merge(format: 'json')
    response.status.should eq(200)
    Oj.load(response.body)["tests"]
  end

  context "Locations" do
    let(:parent_location) {Location.make}
    let(:leaf_location1) {Location.make parent: parent_location}
    let(:leaf_location2) {Location.make parent: parent_location}
    let(:upper_leaf_location) {Location.make}

    let(:laboratory1) {Laboratory.make institution: institution, location_geoid: leaf_location1.id}
    let(:laboratory2) {Laboratory.make institution: institution, location_geoid: leaf_location2.id}
    let(:laboratory3) {Laboratory.make institution: institution, location_geoid: upper_leaf_location.id}

    it "filters by location" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]

      DeviceMessage.create_and_process device: device1, plain_text_data: Oj.dump(test:{assays:[name: "flu_a"]})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[name: "flu_b"]})
      DeviceMessage.create_and_process device: device3, plain_text_data: Oj.dump(test:{assays:[name: "mtb"]})

      response = get_updates(location: leaf_location1.geo_id)

      response.first["test"]["assays"].first["name"].should eq("flu_a")

      response = get_updates(location: leaf_location2.geo_id)

      response.first["test"]["assays"].first["name"].should eq("flu_b")

      response = get_updates(location: parent_location.geo_id).sort_by do |test|
        test["test"]["assays"].first["name"]
      end

      response.size.should eq(2)
      response[0]["test"]["assays"].first["name"].should eq("flu_a")
      response[1]["test"]["assays"].first["name"].should eq("flu_b")
    end

    it "groups by administrative level" do
      device1 = Device.make institution: institution, laboratories: [laboratory1]
      device2 = Device.make institution: institution, laboratories: [laboratory2]
      device3 = Device.make institution: institution, laboratories: [laboratory3]

      DeviceMessage.create_and_process device: device1, plain_text_data: Oj.dump(test:{assays:[name: "flu_a"]})
      DeviceMessage.create_and_process device: device2, plain_text_data: Oj.dump(test:{assays:[name: "flu_b"]})
      DeviceMessage.create_and_process device: device3, plain_text_data: Oj.dump(test:{assays:[name: "mtb"]})

      response = get_updates(group_by: {admin_level: 0})
      response.should eq([
        {"location.admin_levels"=>parent_location.geo_id, "count"=>2},
        {"location.admin_levels"=>upper_leaf_location.geo_id, "count"=>1}
      ])
    end
  end

end
