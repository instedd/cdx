require 'spec_helper'
include Policy::Actions

describe Resource do
  let!(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }

  it "should return the resource for a given instance matcher" do
    expect(Resource.find("#{PREFIX}:institution/#{institution.id}")).to eq(institution)
  end

  it "should return the resource for a given class matcher" do
    expect(Resource.find("#{PREFIX}:institution/*")).to eq(Institution)
    expect(Resource.find("#{PREFIX}:institution")).to eq(Institution)
  end

  it "should return nil if the resource is invalid" do
    expect(Resource.find("foo")).to be_nil
  end

  it "should return all the resources if matcher is '*'" do
    expect(Resource.find("*")).to eq(Resource.all)
  end
end
