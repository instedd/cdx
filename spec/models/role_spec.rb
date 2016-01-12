require 'spec_helper'

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
end
