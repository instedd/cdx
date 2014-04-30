require 'spec_helper'

describe InstitutionsController do
  let(:current_user) { User.make }

  before(:each) { sign_in current_user }

  describe "create" do
    before(:each) { post :create, institution: Institution.plan }

    it "creates it" do
      Institution.count.should eq(1)
    end

    it "makes the user admin of it" do
      current_user.has_role?(:admin, Institution.last).should be_true
    end

    it "makes the user member of it" do
      current_user.has_role?(:member, Institution.last).should be_true
    end
  end

  describe "update" do
    before(:each) { current_user.create(Institution.make_unsaved(name: "Foo")) }

    it "allows for admin" do
      put :update, id: Institution.last.id, institution: {name: "Bar"}

      Institution.last.name.should eq("Bar")
    end

    it "allows for another admin" do
      another_user = User.make
      another_user.add_role :admin, Institution.last
      another_user.add_role :member, Institution.last

      sign_in another_user
      put :update, id: Institution.last.id, institution: {name: "Bar"}

      Institution.last.name.should eq("Bar")
    end

    it "disallows for another member" do
      another_user = User.make
      another_user.add_role :member, Institution.last

      sign_in another_user
      put :update, id: Institution.last.id, institution: {name: "Bar"}

      response.status.should eq(401)
      Institution.last.name.should eq("Foo")
    end

    it "disallows for non-member" do
      another_user = User.make

      sign_in another_user
      lambda {
        put :update, id: Institution.last.id, institution: {name: "Bar"}
      }.should raise_exception

      Institution.last.name.should eq("Foo")
    end
  end

  describe "destroy" do
    before(:each) { current_user.create(Institution.make_unsaved(name: "Foo")) }

    it "allows for admin" do
      delete :destroy, id: Institution.last.id

      Institution.count.should eq(0)
    end

    it "allows for another admin" do
      another_user = User.make
      another_user.add_role :admin, Institution.last
      another_user.add_role :member, Institution.last

      sign_in another_user

      delete :destroy, id: Institution.last.id

      Institution.count.should eq(0)
    end

    it "disallows for another member" do
      another_user = User.make
      another_user.add_role :member, Institution.last

      sign_in another_user

      delete :destroy, id: Institution.last.id

      response.status.should eq(401)
      Institution.count.should eq(1)
    end

    it "disallows for non-member" do
      another_user = User.make

      sign_in another_user

      lambda {
        delete :destroy, id: Institution.last.id
      }.should raise_exception

      Institution.count.should eq(1)
    end
  end
end
