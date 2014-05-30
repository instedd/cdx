require 'spec_helper'
include Policy::Actions

describe Resource do
  let!(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }

  it "should have record of all the resources in the system" do
    Resource.all.should eq([Institution])
  end

  it "should return the resource for a given instance matcher" do
    Resource.find("#{PREFIX}:institution/#{institution.id}").should eq(institution)
  end

  it "should return the resource for a given class matcher" do
    Resource.find("#{PREFIX}:institution/*").should be(Institution)
  end

  it "should return all the resources if matcher is '*'" do
    Resource.find("*").should eq(Resource.all)
  end
end
