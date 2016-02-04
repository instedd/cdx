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
      patch :update, id: site.id, site: { name: "newname", location_geoid: "LOCATION_GEOID", lat: 40, lng: 50 }
      expect(site.reload.name).to eq("newname")
      expect(site.reload.lat).to eq(40)
      expect(site.reload.lng).to eq(50)
      expect(response).to be_redirect
    end

    it "should update site inferring latlng from geoid" do
      expect(Location).to receive(:details).with("LOCATION_GEOID") { [Location.new.tap {|l| l.lat= 10; l.lng= -42}] }
      patch :update, id: site.id, site: { name: "newname", location_geoid: "LOCATION_GEOID" }
      expect(site.reload.name).to eq("newname")
      expect(site.reload.lat).to eq(10)
      expect(site.reload.lng).to eq(-42)
      expect(response).to be_redirect
    end

    it "should not update site for another institution" do
      patch :update, id: site2.id, site: { name: "newname" }
      expect(site2.reload.name).to_not eq("newname")
      expect(response).to be_forbidden
    end

    it "should not update parent site if user has no institution:createSite but yes other properties" do
      new_parent = institution.sites.make

      other_user = User.make
      grant user, other_user, institution, [READ_INSTITUTION]
      grant user, other_user, "site?institution=#{institution.id}", [READ_SITE]
      grant user, other_user, "site?institution=#{institution.id}", [UPDATE_SITE]

      sign_in other_user
      expect {
        patch :update, id: site.id, site: { name: 'newname', parent_id: new_parent.id }
      }.to change(Site, :count).by(0)

      expect(site.reload.name).to eq("newname")
      expect(site.reload.parent).to_not eq(new_parent)
    end

    context "change parent site by user with institution:createSite policy" do
      let!(:new_parent) { institution.sites.make }
      let(:new_site) { Site.last }
      let!(:device) { Device.make site: site }
      let!(:test) { TestResult.make device: device }

      before(:each) {
        patch :update, id: site.id, site: (
          Site.plan(institution: institution).merge({ parent_id: new_parent.id, name: site.name })
        )

        site.reload
      }

      it "should create a new site with the name of the edited" do
        expect(new_site.id).to_not eq(new_parent.id)
        expect(new_site.id).to_not eq(site.id)
        expect(new_site.name).to eq(site.name)
      end

      it "should redirect to sites_path" do
        expect(response).to redirect_to(sites_path)
      end

      it "should soft delete original site" do
        expect(site).to be_deleted
      end

      it "should leave original without devices" do
        expect(site.devices).to be_empty
      end

      it "should leave test in original site" do
        expect(site.test_results).to eq([test])
      end

      it "should leave devices in new site" do
        expect(new_site.devices).to eq([device])
      end

      it "should leave no test in new site" do
        expect(new_site.test_results).to be_empty
      end
    end

    context "changing parent site and with some validation errors" do
      let!(:new_parent) { institution.sites.make }

      before(:each) {
        patch :update, id: site.id, site: (
          Site.plan(institution: institution).merge({ parent_id: new_parent.id, name: '' })
        )

        site.reload
      }

      it "should not create a new site" do
        expect(Site.last.id).to eq(new_parent.id)
      end

      it "should not delete the original site" do
        expect(site).to_not be_deleted
      end

      it "should try to update the original site in the form" do
        expect(response.body).to include(%(class="edit_site" id="edit_site_#{site.id}" action="/sites/#{site.id}))
      end

      it "should keep edited values of attributes" do
        expect(assigns(:site).name).to eq('')
      end
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
