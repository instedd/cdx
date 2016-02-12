require 'spec_helper'
require 'policy_spec_helper'

describe Role do
  it "should validate that site belongs to institution" do
    role = Role.make_unsaved
    institution = Institution.make
    role.site = Site.make institution: institution
    role.institution = institution
    role.policy = Policy.make definition: policy_definition(institution, CREATE_INSTITUTION, true), user: User.make, granter: institution.user
    # At this point the role is valid
    expect(role).to be_valid

    role.institution = Institution.make
    expect(role).to be_invalid
  end

  context "within" do
    let!(:site) { Site.make }
    let!(:subsite) { Site.make parent: site, institution: site.institution }
    let!(:other_site) { Site.make }

    # Roles are automatically created with institutions and sites.
    # At this time, it's 2 per institution and 4 per site
    it "institution, no exclusion, should show roles from site, subsites and no site" do
      expect(Role.within(site.institution).count).to eq(10)
    end

    it "institution, with exclusion, should show strictly institution roles" do
      expect(Role.within(site.institution,true).count).to eq(2)
    end

    it "site, no exclusion, should show roles from site and subsite" do
      expect(Role.within(site).count).to eq(8)
    end

    it "site, with exclusion, should show devices from site only" do
      expect(Role.within(site,true).count).to eq(4)
    end

    it "institution should not show devices from other institutions" do
      roles = Role.within(other_site.institution)
      expect(roles.count).to eq(6)
      expect(roles.any?{|r| r.name.include?(site.institution.name)}).to be false
    end
  end
end
