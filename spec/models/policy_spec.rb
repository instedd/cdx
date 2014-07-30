require 'spec_helper'

include Policy::Actions

describe Policy do
  let(:user) { User.make }
  let(:institution) { user.create Institution.make_unsaved }

  it "doesn't allow a user to read his institutions without the implicit policy" do
    user.policies.destroy_all
    user.reload

    assert_cannot user, Institution, READ_INSTITUTION
  end

  it "allows a user to read only his institutions" do
    user2, institution2 = create_user_and_institution

    assert_can user, Institution, READ_INSTITUTION, [institution]
  end

  it "allows a user to update his institution" do
    assert_can user, institution, UPDATE_INSTITUTION
  end

  it "doesn't allows a user to update an instiutiton he is not an owner of" do
    user2, institution2 = create_user_and_institution

    assert_cannot user, institution2, UPDATE_INSTITUTION
  end

  it "allows a user to read an institution" do
    user.policies.destroy_all
    user2, institution2 = create_user_and_institution
    grant user2, user, institution2, [READ_INSTITUTION, UPDATE_INSTITUTION]
    user.reload

    assert_can user, institution2, READ_INSTITUTION
  end

  it "allows a user to read all institutions" do
    user2, institution2 = create_user_and_institution

    grant user2, user, Institution, [READ_INSTITUTION, UPDATE_INSTITUTION]

    assert_can user, Institution, READ_INSTITUTION, [institution, institution2]
  end

  it "doesn't allow a user to read another institution" do
    user2, institution2 = create_user_and_institution
    institution3 = user2.create Institution.make_unsaved

    grant user2, user, institution3, [READ_INSTITUTION, UPDATE_INSTITUTION]

    assert_cannot user, institution2, READ_INSTITUTION
  end

  it "allows a user to list an institution" do
    user2, institution2 = create_user_and_institution

    grant user2, user, institution2, [READ_INSTITUTION, UPDATE_INSTITUTION]

    assert_can user, Institution, READ_INSTITUTION, [institution, institution2]
  end

  it "allows reading all institutions if superadmin" do
    user2, institution2 = create_user_and_institution

    policy = Policy.superadmin
    policy.granter_id = nil
    policy.user_id = user.id
    policy.save(validate: false)

    assert_can user, Institution, READ_INSTITUTION, [institution, institution2]
  end

  it "disallows read one institution if granter doesn't have a permission for it" do
    user2 = User.make
    user3, institution3 = create_user_and_institution

    policy = grant user3, user, institution3, READ_INSTITUTION
    grant user, user2, institution3, READ_INSTITUTION
    policy.destroy

    assert_cannot user2, institution3, READ_INSTITUTION
  end

  it "disallows read all institution if granter doesn't have a permission for it" do
    user2 = User.make
    user3, institution3 = create_user_and_institution

    grant user, user2, Institution, READ_INSTITUTION

    assert_can user2, Institution, READ_INSTITUTION, [institution]
  end

  it "allows to read institutions even if the granter doesn't have institutions created" do
    user.policies.destroy_all
    user2 = User.make
    create_user_and_institution
    grant user2, user, Institution, READ_INSTITUTION
    user.reload

    can = Policy.can? READ_INSTITUTION, Institution, user
    institutions = Policy.authorize READ_INSTITUTION, Institution, user

    can.should be_true
    institutions.should eq([])
  end

  it "disallows delegable" do
    user2 = User.make
    user3 = User.make

    policy = grant user, user2, institution, READ_INSTITUTION, true

    grant user2, user3, institution, READ_INSTITUTION, true

    policy.definition = policy_definition(institution, READ_INSTITUTION, false)
    policy.save!

    assert_cannot user3, institution, READ_INSTITUTION
  end

  it "allows delegable with disallow from one branch" do
    user2 = User.make
    user3 = User.make
    user4 = User.make

    grant user, user2, institution, READ_INSTITUTION, false
    grant user, user3, institution, READ_INSTITUTION, true
    grant user3, user4, institution, READ_INSTITUTION, true

    assert_can user4, institution, READ_INSTITUTION
  end

  it "disallows policy creation if granter can't delegate it" do
    user2 = User.make
    user3 = User.make

    grant user, user2, institution, READ_INSTITUTION, false

    policy = Policy.make_unsaved
    policy.definition = policy_definition(institution, READ_INSTITUTION, false)
    policy.granter_id = user2.id
    policy.user_id = user3.id
    policy.save.should be_false

    action = Policy::READ_INSTITUTION
    resource = institution
    policies = [policy]

    result = Policy.can? action, resource, user3, policies
    result.should be_false
  end

  it "disallows policy creation if self-granted" do
    policy = Policy.make_unsaved
    policy.definition = policy_definition(institution, READ_INSTITUTION, false)
    policy.granter_id = user.id
    policy.user_id = user.id
    policy.save.should be_false
  end

  it "disallows policy creation if granter is nil" do
    policy = Policy.make_unsaved
    policy.definition = policy_definition(institution, READ_INSTITUTION, false)
    policy.granter_id = nil
    policy.user_id = user.id
    policy.save.should be_false
  end

  it "allows checking when there's a loop" do
    user2, institution2 = create_user_and_institution
    user3, institution3 = create_user_and_institution

    grant user2, user3, institution2, READ_INSTITUTION
    grant user3, user2, institution2, READ_INSTITUTION

    assert_cannot user2, institution3, READ_INSTITUTION
    assert_can user3, institution2, READ_INSTITUTION
  end

  it "disallow read if explicitly denied" do
    user2 = User.make

    grant user, user2, institution, READ_INSTITUTION
    deny user, user2, institution, READ_INSTITUTION

    assert_cannot user2, institution, READ_INSTITUTION
  end

  it "allows reading all institutions except one" do
    institution2 = user.create Institution.make_unsaved
    institution3 = user.create Institution.make_unsaved

    user2 = User.make

    grant user, user2, Institution, READ_INSTITUTION
    deny user, user2, institution3, READ_INSTITUTION

    assert_can user2, Institution, READ_INSTITUTION, [institution, institution2]
  end

  it "disallows creating institution laboratory" do
    user2 = User.make
    assert_cannot user2, institution, CREATE_INSTITUTION_LABORATORY
  end

  it "allows creating institution laboratory" do
    user2 = User.make

    grant user, user2, institution, CREATE_INSTITUTION_LABORATORY

    assert_can user2, institution, CREATE_INSTITUTION_LABORATORY
  end

  it "disallows reading institution laboratory" do
    laboratory = institution.laboratories.make

    user2 = User.make
    assert_cannot user2, laboratory, READ_LABORATORY
  end

  it "allows reading self institution laboratory" do
    laboratory = institution.laboratories.make

    assert_can user, laboratory, READ_LABORATORY, [laboratory]
  end

  it "allows reading self laboratories" do
    laboratory = institution.laboratories.make

    assert_can user, institution.laboratories, READ_LABORATORY, [laboratory]
  end

  it "allows reading other institution laboratory" do
    laboratory = institution.laboratories.make
    user2 = User.make

    grant user, user2, laboratory, READ_LABORATORY

    assert_can user2, laboratory, READ_LABORATORY, [laboratory]
  end

  it "allows reading other laboratories" do
    laboratory = institution.laboratories.make
    user2 = User.make

    grant user, user2, Laboratory, READ_LABORATORY

    assert_can user2, Laboratory, READ_LABORATORY, [laboratory]
  end

  it "allows reading other laboratories (2)" do
    laboratory = institution.laboratories.make
    user2 = User.make

    grant user, user2, Laboratory, READ_LABORATORY

    assert_can user2, laboratory, READ_LABORATORY
  end

  it "allows reading other institution laboratories" do
    laboratory = institution.laboratories.make
    user2 = User.make

    grant user, user2, "#{Laboratory.resource_name}?institution=#{institution.id}", READ_LABORATORY

    assert_can user2, Laboratory, READ_LABORATORY, [laboratory]
  end

  it "disallows reading other institution laboratories when id is other" do
    institution2 = user.create Institution.make_unsaved

    laboratory = institution.laboratories.make
    user2 = User.make

    grant user, user2, "#{Laboratory.resource_name}?institution=#{institution2.id}", READ_LABORATORY

    assert_cannot user2, laboratory, READ_LABORATORY
  end

  it "allows a user to read institutions even if there are no institutions on the system" do
    user2 = User.make
    can = Policy.can? READ_INSTITUTION, Institution, user2
    institutions = Policy.authorize READ_INSTITUTION, Institution, user2

    can.should be_true
    institutions.should eq([])
  end

  def create_user_and_institution
    user = User.make
    institution = user.create Institution.make_unsaved
    [user, institution]
  end

  def assert_can(user, resource, action, expected_result = [resource])
    result = Policy.can? action, resource, user

    result.should be_true

    result = Policy.authorize action, resource, user
    result = result.sort_by &:id
    expected_result = expected_result.sort_by &:id

    result.should eq(expected_result)
  end

  def assert_cannot(user, resource, action)
    result = Policy.cannot? action, resource, user
    result.should be_true
  end

  def grant(granter, user, resource, action, delegable = true)
    grant_or_deny granter, user, resource, action, delegable, "allow"
  end

  def deny(granter, user, resource, action, delegable = true)
    grant_or_deny granter, user, resource, action, delegable, "deny"
  end

  def grant_or_deny(granter, user, resource, action, delegable, effect)
    policy = Policy.make_unsaved
    policy.definition = policy_definition(resource, action, delegable, effect)
    policy.granter_id = granter.id
    policy.user_id = user.id
    policy.save!
    policy
  end

  def policy_definition(resource, action, delegable = true, effect = "allow")
    resource = Array(resource).map(&:resource_name)
    action = Array(action)

    JSON.parse %(
      {
        "statement":  [
          {
            "effect": "#{effect}",
            "action": #{action.to_json},
            "resource": #{resource.to_json}
          }
        ],
        "delegable": #{delegable}
      }
    )
  end
end
