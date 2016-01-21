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

end
