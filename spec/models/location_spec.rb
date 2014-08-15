require 'spec_helper'

describe Location do
  let(:root_location) {Location.create_default}

  it "requires admin_level" do
    location = Location.create
    location.errors.keys.should include(:admin_level)
    Location.create(admin_level: 2, parent: root_location).errors.should be_empty
  end

  it "restricts admin_level to be below the parent's admin_level" do
    location1 = Location.create! admin_level: 2, parent: root_location
    location2 = Location.create admin_level: 1, parent: location1
    location2.errors.messages.should include(:admin_level=>["must be below parent's admin_level"])
  end

  it "prevents the creation of a location without a parent" do
    location = Location.create
    location.errors.keys.should include(:parent)
    Location.create(admin_level: 2, parent: root_location).errors.should be_empty
  end

  it "prevents the creation of a location with parent and without admin level" do
    location = Location.new
    location.parent = root_location
    location.save

    location.errors.keys.should include(:admin_level)
  end
end
