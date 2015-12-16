require 'spec_helper'

describe UsersController do

  let!(:institution) {Institution.make}
  let!(:user) {institution.user}
  before(:each) do
    sign_in user
  end

  context "settings" do
    it "should load page" do
      get :settings
      expect(response).to be_success
    end

    it "should update password" do
      old_pass = user.encrypted_password
      params = {user: {password: '12345678', password_confirmation: "12345678"}}
      post :update_settings, params
      expect(user.reload.encrypted_password).not_to eq(old_pass)
    end

    it "should update other settings when password isn't included" do
      params = {user: {time_zone: 'Brasilia'}}
      post :update_settings, params
      expect(user.reload.time_zone).to eq("Brasilia")
    end

    it "should update other settings when password is empty" do
      params = {user: {time_zone: 'Brasilia', password: '', password_confirmation: ''}}
      post :update_settings, params
      expect(user.reload.time_zone).to eq("Brasilia")
    end

  end

end
