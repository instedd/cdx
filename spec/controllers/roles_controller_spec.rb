require 'spec_helper'
require 'policy_spec_helper'

describe RolesController do

  let!(:institution) {Institution.make}
  let!(:user)        {institution.user}
  let!(:site)        {Site.make institution: institution}

  let!(:institution2) { Institution.make }

  before(:each) {sign_in user}
  let(:default_params) { {context: institution.uuid} }

  context "create" do

    it "should infer the institution from current context" do
      expect {
        post :create, role: {
          name: "Some role",
          site_id: site.id,
          definition: policy_definition('device', '*').to_json
        }
      }.to change(institution.roles, :count).by(1)
      expect(Role.last.institution).to eq(institution)
    end

    it "should infer the institution from current context, even when having access to multiple institutions" do
      grant nil, user, "institution/#{institution2.id}", [READ_INSTITUTION]
      expect {
        post :create, role: {
          name: "Some role",
          site_id: site.id,
          definition: policy_definition('device', '*').to_json
        }
      }.to change(institution.roles, :count).by(1)
      expect(Role.last.institution).to eq(institution)
    end

    it "should infer the institution from current context, even when it's not the default" do
      grant nil, user, "institution/#{institution2.id}", [READ_INSTITUTION]
      expect {
        post :create, role: {
          name: "Some role",
          site_id: site.id,
          definition: policy_definition('device', '*').to_json,
          context: institution2.uuid
        }
      }.to change(institution.roles, :count).by(1)
      expect(Role.last.institution).to eq(institution)
    end

  end

  context "authorizations" do

    let(:grantee) { User.make }

    let!(:site)  { Site.make(institution: institution) }
    let!(:site2) { Site.make(institution: institution2) }

    def create_role(args)
      expect {
        post :create, role: args
      }.to change(institution.roles, :count).by(1)

    end

    def add_grantee_to_role(role_name)
      grantee.roles << Role.where(name: role_name).first
      grantee.update_computed_policies
      grantee.reload
    end

    it "should not allow to access a site from a different institution when not scoping sites in policy" do
      create_role name: "All sites", definition: policy_definition('site', '*').to_json
      add_grantee_to_role 'All sites'

      assert_cannot grantee, site2, 'site:read'
      assert_can grantee, site, 'site:read'
    end

    it "should not allow to access a site from a different institution when scoping by another institution in policy" do
      create_role name: "Sites from institution 2", definition: policy_definition("site?institution=#{institution2.id}", '*').to_json
      add_grantee_to_role "Sites from institution 2"

      assert_cannot grantee, site2, 'site:read'
      assert_cannot grantee, site, 'site:read'
    end

    it "should not allow to access a forbidden resource when creating a role" do
      device_model = DeviceModel.make
      create_role name: "Device models", definition: policy_definition("deviceModel", '*').to_json
      add_grantee_to_role "Device models"

      assert_cannot grantee, device_model, 'deviceModel:read'
    end

  end

end
