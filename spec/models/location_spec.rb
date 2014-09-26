require 'spec_helper'

describe Location do
  let(:root_location) {Location.create_default}

  it "requires admin_level" do
    location = Location.create
    location.errors.keys.should include(:admin_level)
    Location.create(admin_level: 2, parent: root_location, geo_id: '00AA').errors.should be_empty
  end

  it "restricts admin_level to be below the parent's admin_level" do
    location1 = Location.create! admin_level: 2, parent: root_location, geo_id: '00AA'
    location2 = Location.create admin_level: 1, parent: location1, geo_id: '00AB'
    location2.errors.messages.should include(:admin_level=>["must be below parent's admin_level"])
  end

  it "prevents the creation of a location without a parent" do
    location = Location.create
    location.errors.keys.should include(:parent)
    Location.create(admin_level: 2, parent: root_location, geo_id: '00AA').errors.should be_empty
  end

  it "prevents the creation of a location with parent and without admin level" do
    location = Location.new
    location.parent = root_location
    location.save

    location.errors.keys.should include(:admin_level)
  end

  it "prevents the creation of a location with parent and without admin level" do
    location = Location.new
    location.parent = root_location
    location.save

    location.errors.keys.should include(:geo_id)
  end

  it "restricts the geo id" do
    location1 = Location.create! admin_level: 2, parent: root_location, geo_id: '00AA'
    location2 = Location.create admin_level: 3, parent: location1, geo_id: '00AA'
    location2.errors.messages.should include(:geo_id=>["has already been taken"])
  end
end
