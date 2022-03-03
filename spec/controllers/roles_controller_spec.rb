require 'spec_helper'
require 'policy_spec_helper'

describe RolesController do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
    @site = Site.make! institution: @institution

    @institution2 = Institution.make!
  end

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

  context "update" do
    let!(:role) { Role.make! institution: institution }
    let!(:initial_action) { role.policy.definition["statement"][0]["action"][0] }

    it "should begin with non * action" do
      expect(initial_action).to_not eq("*")
    end

    it "should be able to update the policy definition" do
      put :update, id: role.id, role: { name: role.name, definition: policy_definition('device', '*').to_json }
      role.reload
      expect(role.policy.definition["statement"][0]["action"][0]).to eq("*")
    end

    it "should be able to update name" do
      put :update, id: role.id, role: { name: "new-name", definition: policy_definition('device', '*').to_json }
      role.reload
      expect(role.name).to eq("new-name")
      expect(role.policy.definition["statement"][0]["action"][0]).to eq("*")
    end

    it "should not change policy if name is invalid" do
      put :update, id: role.id, role: { name: "", definition: policy_definition('device', '*').to_json }
      role.reload
      expect(role.name).to_not eq("")
      expect(role.policy.definition["statement"][0]["action"][0]).to eq(initial_action)

      expect(response).to render_template(:edit)
      expect(assigns(:role).name).to eq("")
      expect(JSON.parse(assigns(:role).definition)["statement"][0]["action"][0]).to eq("*")
    end

    it "should not change name if policy is empty" do
      put :update, id: role.id, role: { name: "new-name", definition: "{statement:[]}" }
      role.reload
      expect(role.name).to_not eq("new-name")
      expect(role.policy.definition["statement"][0]["action"][0]).to eq(initial_action)

      expect(response).to render_template(:edit)
      expect(assigns(:role).name).to eq("new-name")
      expect(assigns(:role).definition).to eq("{statement:[]}")
    end

    it "should not change name if policy is invalid json" do
      put :update, id: role.id, role: { name: "new-name", definition: "i am not a json" }
      role.reload
      expect(role.name).to_not eq("new-name")
      expect(role.policy.definition["statement"][0]["action"][0]).to eq(initial_action)

      expect(response).to render_template(:edit)
      expect(assigns(:role).name).to eq("new-name")
      expect(assigns(:role).definition).to eq("i am not a json")
    end

    it "should change name only if policy is empty" do
      put :update, id: role.id, role: { name: "new-name", definition: "" }
      role.reload
      expect(role.name).to eq("new-name")
      expect(role.policy.definition["statement"][0]["action"][0]).to eq(initial_action)
    end
  end

  context "authorizations" do

    let(:grantee) { User.make! }

    let!(:site)  { Site.make!(institution: institution) }
    let!(:site2) { Site.make!(institution: institution2) }
    let!(:device) { Device.make!(site: site, institution: institution) }
    let!(:device2) { Device.make!(site: site2, institution: institution2) }

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
      device_model = DeviceModel.make!
      create_role name: "Device models", definition: policy_definition("deviceModel", '*').to_json
      add_grantee_to_role "Device models"

      assert_cannot grantee, device_model, 'deviceModel:read'
    end

    it "should update computed policies when updating a role which users already have" do
      create_role name: "All sites", definition: policy_definition('site', '*').to_json
      add_grantee_to_role 'All sites'
      post :update, id: Role.find_by_name('All sites').id, role: { name: "All sites", definition: policy_definition('device', '*').to_json }

      assert_cannot grantee, device2, 'device:read'
      assert_can grantee, device, 'device:read'
    end

  end

end
