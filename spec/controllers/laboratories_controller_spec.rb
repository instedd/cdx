require 'spec_helper'

describe LaboratoriesController do
  let(:current_user) { User.make }
  let(:institution) do
    institution = Institution.make_unsaved
    current_user.create(institution)
    institution
  end

  before(:each) { sign_in current_user }

  describe "create" do
    it "creates it" do
      post :create, institution_id: institution.id, laboratory: Laboratory.plan

      institution.laboratories.count.should eq(1)
    end

    it "allows another admin to create it" do
      another_user = User.make
      another_user.add_role :admin, institution
      another_user.add_role :member, institution
      sign_in another_user

      post :create, institution_id: institution.id, laboratory: Laboratory.plan

      institution.laboratories.count.should eq(1)
    end

    it "disallows another member to create it" do
      another_user = User.make
      another_user.add_role :member, institution
      sign_in another_user

      post :create, institution_id: institution.id, laboratory: Laboratory.plan

      response.status.should eq(401)
      institution.laboratories.count.should eq(0)
    end
  end

  describe "update" do
    before(:each) { current_user.create(institution.laboratories.make_unsaved(name: "Foo")) }

    it "allows for admin" do
      put :update, id: Laboratory.last.id, institution_id: institution.id, laboratory: {name: "Bar"}

      Laboratory.last.name.should eq("Bar")
    end

    it "allows for another institution admin" do
      another_user = User.make
      another_user.add_role :admin, institution
      another_user.add_role :member, institution
      sign_in another_user

      put :update, id: Laboratory.last.id, institution_id: institution.id, laboratory: {name: "Bar"}

      Laboratory.last.name.should eq("Bar")
    end

    it "allows for another laboratory admin" do
      another_user = User.make
      another_user.add_role :member, institution
      another_user.add_role :admin, Laboratory.last
      sign_in another_user

      put :update, id: Laboratory.last.id, institution_id: institution.id, laboratory: {name: "Bar"}

      Laboratory.last.name.should eq("Bar")
    end

    it "disallows for institution member" do
      another_user = User.make
      another_user.add_role :member, institution
      sign_in another_user

      lambda {
        put :update, id: Laboratory.last.id, institution_id: institution.id, laboratory: {name: "Bar"}
      }.should raise_exception

      Laboratory.last.name.should eq("Foo")
    end
  end

  describe "destroy" do
    before(:each) { current_user.create(institution.laboratories.make_unsaved(name: "Foo")) }

    it "allows for admin" do
      delete :destroy, institution_id: institution.id, id: Laboratory.last.id

      Laboratory.count.should eq(0)
    end

    it "allows for another institution admin" do
      another_user = User.make
      another_user.add_role :admin, institution
      another_user.add_role :member, institution
      sign_in another_user

      delete :destroy, institution_id: institution.id, id: Laboratory.last.id

      Laboratory.count.should eq(0)
    end

    it "allows for another laboratory admin" do
      another_user = User.make
      another_user.add_role :member, institution
      another_user.add_role :admin, Laboratory.last
      sign_in another_user

      delete :destroy, institution_id: institution.id, id: Laboratory.last.id

      Laboratory.count.should eq(0)
    end

    it "disallows for another institution member" do
      another_user = User.make
      another_user.add_role :member, institution
      sign_in another_user

      lambda {
        delete :destroy, institution_id: institution.id, id: Laboratory.last.id
      }.should raise_exception

      Laboratory.count.should eq(1)
    end
  end
end
