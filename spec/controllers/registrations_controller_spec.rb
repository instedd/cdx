require 'spec_helper'

describe RegistrationsController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
  end

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
  end

  context "edit settings" do

    it "should load page" do
      get :edit, context: institution.uuid
      expect(response).to be_success
      expect(assigns(:locales)).to be_a(Array)
    end

    it "should update password" do
      old_pass = user.encrypted_password
      params = {user: {password: '12345678', password_confirmation: "12345678"}}
      post :update, params
      expect(user.reload.encrypted_password).not_to eq(old_pass)
    end

    it "should not update password if confirmation does not match" do
      old_pass = user.encrypted_password
      params = {user: {password: '12345678', password_confirmation: "DIFFERENT"}}
      post :update, params
      expect(user.reload.encrypted_password).to eq(old_pass)
    end

    it "should not update password if confirmation is blank" do
      old_pass = user.encrypted_password
      params = {user: {password: '12345678', password_confirmation: ""}}
      post :update, params
      expect(user.reload.encrypted_password).to eq(old_pass)
    end

    it "should not update password if confirmation is not set" do
      old_pass = user.encrypted_password
      params = {user: {password: '12345678'}}
      post :update, params
      expect(user.reload.encrypted_password).to eq(old_pass)
    end

    it "should update other settings when password isn't included" do
      params = {user: {time_zone: 'Brasilia'}}
      post :update, params
      expect(user.reload.time_zone).to eq("Brasilia")
    end

    it "should update other settings when password is empty" do
      params = {user: {time_zone: 'Brasilia', password: '', password_confirmation: ''}}
      post :update, params
      expect(user.reload.time_zone).to eq("Brasilia")
    end

  end
end
