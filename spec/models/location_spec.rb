require 'spec_helper'

describe Location do
  let(:root_location) {Location.create_default}

  it "can create new locations" do
    Location.create(parent: root_location, geo_id: '00AA').errors.should be_empty
  end

  it "prevents the creation of a location without a parent" do
    location = Location.create
    location.errors.keys.should include(:parent)
  end

  it "prevents the creation of a location with parent and without geo_id" do
    location = Location.new
    location.parent = root_location
    location.save

    location.errors.keys.should include(:geo_id)
  end

  it "restricts the geo id" do
    location1 = Location.create! parent: root_location, geo_id: '00AA'
    location2 = Location.create parent: location1, geo_id: '00AA'
    location2.errors.messages.should include(:geo_id=>["has already been taken"])
  end
end
