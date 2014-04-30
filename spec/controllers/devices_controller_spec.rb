require 'spec_helper'

describe DevicesController do
  let(:current_user) { User.make }
  let(:institution) do
    institution = Institution.make_unsaved
    current_user.create(institution)
    institution
  end

  before(:each) { sign_in current_user }

  describe "create" do
    it "creates it" do
      post :create, institution_id: institution.id, device: Device.plan

      institution.devices.count.should eq(1)
    end

    it "allows another admin to create it" do
      another_user = User.make
      another_user.add_role :admin, institution
      another_user.add_role :member, institution
      sign_in another_user

      post :create, institution_id: institution.id, device: Device.plan

      institution.devices.count.should eq(1)
    end

    it "disallows another member to create it" do
      another_user = User.make
      another_user.add_role :member, institution
      sign_in another_user

      post :create, institution_id: institution.id, device: Device.plan

      response.status.should eq(401)
      institution.devices.count.should eq(0)
    end
  end

  describe "update" do
    before(:each) { current_user.create(institution.devices.make_unsaved(name: "Foo")) }

    it "allows for admin" do
      put :update, id: Device.last.id, institution_id: institution.id, device: {name: "Bar"}

      Device.last.name.should eq("Bar")
    end

    it "allows for another institution admin" do
      another_user = User.make
      another_user.add_role :admin, institution
      another_user.add_role :member, institution
      sign_in another_user

      put :update, id: Device.last.id, institution_id: institution.id, device: {name: "Bar"}

      Device.last.name.should eq("Bar")
    end

    it "allows for another device admin" do
      another_user = User.make
      another_user.add_role :member, institution
      another_user.add_role :admin, Device.last
      sign_in another_user

      put :update, id: Device.last.id, institution_id: institution.id, device: {name: "Bar"}

      Device.last.name.should eq("Bar")
    end

    it "disallows for institution member" do
      another_user = User.make
      another_user.add_role :member, institution
      sign_in another_user

      lambda {
        put :update, id: Device.last.id, institution_id: institution.id, device: {name: "Bar"}
      }.should raise_exception

      Device.last.name.should eq("Foo")
    end
  end

  describe "destroy" do
    before(:each) { current_user.create(institution.devices.make_unsaved(name: "Foo")) }

    it "allows for admin" do
      delete :destroy, institution_id: institution.id, id: Device.last.id

      Device.count.should eq(0)
    end

    it "allows for another institution admin" do
      another_user = User.make
      another_user.add_role :admin, institution
      another_user.add_role :member, institution
      sign_in another_user

      delete :destroy, institution_id: institution.id, id: Device.last.id

      Device.count.should eq(0)
    end

    it "allows for another device admin" do
      another_user = User.make
      another_user.add_role :member, institution
      another_user.add_role :admin, Device.last
      sign_in another_user

      delete :destroy, institution_id: institution.id, id: Device.last.id

      Device.count.should eq(0)
    end

    it "disallows for another institution member" do
      another_user = User.make
      another_user.add_role :member, institution
      sign_in another_user

      lambda {
        delete :destroy, institution_id: institution.id, id: Device.last.id
      }.should raise_exception

      Device.count.should eq(1)
    end
  end
end
