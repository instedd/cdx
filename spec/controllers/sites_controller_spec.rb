require 'spec_helper'
require 'policy_spec_helper'

describe SitesController do

  let!(:institution) {Institution.make}
  let!(:user)        {institution.user}

  let!(:institution2) { Institution.make }
  let!(:site2)  { institution2.sites.make }

  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

  context "index" do

    let!(:site) { institution.sites.make }
    let!(:other_site) { Site.make }

    it "should get accessible sites in index" do
      get :index

      expect(response).to be_success
      expect(assigns(:sites)).to contain_exactly(site)
      expect(assigns(:can_create)).to be_truthy
    end

    it "should list sites without location" do
      unlocated_site = institution.sites.make(location: nil)
      get :index

      expect(response).to be_success
      expect(assigns(:sites)).to contain_exactly(site, unlocated_site)
    end

    it "should filter by institution if requested" do
      grant institution2.user, user, Institution, [READ_INSTITUTION]
      grant nil, user, "site?institution=#{institution2.id}", [READ_SITE]

      get :index, context: institution2.uuid

      expect(response).to be_success
      expect(assigns(:sites)).to contain_exactly(site2)
    end

  end

  context "new" do
    let!(:site) { institution.sites.make }

    it "should get new page" do
      get :new
      expect(response).to be_success
    end

    it "should initialize no parent if context is institution" do
      get :new, context: institution.uuid
      expect(response).to be_success
      expect(assigns(:site).parent).to be_nil
    end

    it "should initialize parent if context is site" do
      get :new, context: site.uuid
      expect(response).to be_success
      expect(assigns(:site).parent).to eq(site)
    end
  end

  context "create" do

    it "should create new site in context institution" do
      expect {
        post :create, site: Site.plan
      }.to change(institution.sites, :count).by(1)
      expect(response).to be_redirect
    end

    it "should not create site in context institution despite params" do
      expect {
        post :create, site: Site.plan(institution: institution2)
      }.to change(institution.sites, :count).by(1)
      expect(response).to be_redirect
    end

    it "should not create site in institution without permission to create site" do
      grant institution2.user, user, Institution, [READ_INSTITUTION]
      expect {
        post :create, context: institution2.uuid, site: Site.plan
      }.to change(institution.sites, :count).by(0)
      expect(response).to be_forbidden
    end

    it "should create if no location geoid" do
      expect {
        site = Site.plan(institution: institution)
        site.delete :location_geoid
        post :create, site: site
      }.to change(institution.sites, :count).by(1)
      expect(response).to be_redirect
    end

  end

  context "edit" do

    let!(:site) { institution.sites.make }
    let!(:other_site) { Site.make }

    it "should edit site" do
      get :edit, id: site.id
      expect(response).to be_success
    end

    it "should not edit site if not allowed" do
      get :edit, id: site2.id
      expect(response).to be_forbidden
    end

  end

  context "update" do

    let!(:site) { institution.sites.make }

    it "should update site" do
      expect(Location).to receive(:details) { [Location.new(lat: 10, lng: -42)] }
      patch :update, id: site.id, site: { name: "newname" }
      expect(site.reload.name).to eq("newname")
      expect(response).to be_redirect
    end

    it "should not update site for another institution" do
      patch :update, id: site2.id, site: { name: "newname" }
      expect(site2.reload.name).to_not eq("newname")
      expect(response).to be_forbidden
    end

  end

  context "destroy" do

    let!(:site) { institution.sites.make }

    it "should destroy a site" do
      expect {
        delete :destroy, id: site.id
      }.to change(institution.sites, :count).by(-1)
      expect(response).to be_redirect
    end

    it "should not destroy site for another institution" do
      expect {
        delete :destroy, id: site2.id
      }.to change(institution2.sites, :count).by(0)
      expect(response).to be_forbidden
    end

    it "should not destroy site with associated devices" do
      site.devices.make
      expect(site.devices).not_to be_empty
      expect {
        expect {
          delete :destroy, id: site.id
        }.to raise_error(ActiveRecord::DeleteRestrictionError)
      }.not_to change(institution.sites, :count)
    end

    it "should destroy a site after moving it's associated devices" do
      site3 = institution.sites.make
      site.devices.make
      expect(site.devices).not_to be_empty
      expect {
        expect {
          delete :destroy, id: site.id
        }.to raise_error(ActiveRecord::DeleteRestrictionError)
      }.not_to change(institution.sites, :count)

      site.devices.each { |dev|
        dev.site = site3
        dev.save!
      }

      expect {
        delete :destroy, id: site.id
      }.to change(institution.sites, :count).by(-1)
    end

  end

end
