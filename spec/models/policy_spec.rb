require 'spec_helper'

describe Policy do
  let!(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }

  it "doesn't allow a user to read his institutions without the implicit policy" do
    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = []

    result = Policy.check_all action, resource, policies, user
    result.should be_nil
  end

  it "allows a user to read his institutions" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.should eq([institution])
  end

  it "allows a user to update his institution" do
    action = Policy::UPDATE_INSTITUTION
    resource = institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.should eq([institution])
  end

  it "doesn't allows a user to update an instiutiton he is not an owner of" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = Policy::UPDATE_INSTITUTION
    resource = institution2
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.should be_nil
  end

  it "allows a user to read an institution" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    policy= Policy.new
    policy.definition = JSON.parse %(
                                      {
                                        "statement":  [
                                          {
                                            "effect": "allow",
                                            "action": [
                                              "#{Policy::READ_INSTITUTION}",
                                              "#{Policy::UPDATE_INSTITUTION}"
                                            ],
                                            "resource": "cdpx:institution/#{institution2.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    action = Policy::READ_INSTITUTION
    resource = institution2
    policies = [policy]

    result = Policy.check_all action, resource, policies, user
    result.should eq([institution2])
  end

  it "doesn't allows a user to read another institution" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved
    institution3 = user2.create Institution.make_unsaved

    policy= Policy.new
    policy.definition = JSON.parse %(
                                      {
                                        "statement":  [
                                          {
                                            "effect": "allow",
                                            "action": [
                                              "#{Policy::READ_INSTITUTION}",
                                              "#{Policy::UPDATE_INSTITUTION}"
                                            ],
                                            "resource": "cdpx:institution/#{institution3.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    action = Policy::READ_INSTITUTION
    resource = institution2
    policies = [policy]

    result = Policy.check_all action, resource, policies, user
    result.should be_nil
  end

  it "allows a user to list an institution" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    policy= Policy.new
    policy.definition = JSON.parse %(
                                      {
                                        "statement":  [
                                          {
                                            "effect": "allow",
                                            "action": [
                                              "#{Policy::READ_INSTITUTION}",
                                              "#{Policy::UPDATE_INSTITUTION}"
                                            ],
                                            "resource": "cdpx:institution/#{institution2.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = [policy]

    result = Policy.check_all action, resource, policies, user
    result.should eq([institution2])
  end

  it "allows reading all institutions if superadmin" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = [Policy.implicit, Policy.superadmin]

    result = Policy.check_all action, resource, policies, user
    result.should eq([institution, institution2])
  end

  it "disallows read one institution if granter doesn't have a permission for it" do
    user2 = User.make

    user3 = User.make
    institution3 = user3.create Institution.make_unsaved

    # user gives user2 permission to read institution3
    policy = Policy.new
    policy.name = "user2 can read institution3"
    policy.definition = JSON.parse %(
                                      {
                                        "statement":  [
                                          {
                                            "effect": "allow",
                                            "action": [
                                              "#{Policy::READ_INSTITUTION}"
                                            ],
                                            "resource": "cdpx:institution/#{institution3.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    policy.user_id = user2.id
    policy.granter_id = user.id
    policy.save!

    # user2 shouldn't be able to read institution3
    action = Policy::READ_INSTITUTION
    resource = institution3
    policies = user2.policies

    result = Policy.check_all action, resource, policies, user2
    result.should be_nil
  end

  it "disallows read all institution if granter doesn't have a permission for it" do
    user2 = User.make

    user3 = User.make
    institution3 = user3.create Institution.make_unsaved

    # user gives user2 permission to read all institutions
    policy = Policy.new
    policy.name = "user2 can read all institutions"
    policy.definition = JSON.parse %(
                                      {
                                        "statement":  [
                                          {
                                            "effect": "allow",
                                            "action": [
                                              "#{Policy::READ_INSTITUTION}"
                                            ],
                                            "resource": "cdpx:institution/*"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    policy.user_id = user2.id
    policy.granter_id = user.id
    policy.save!

    # user2 shouldn't be able to read any institution
    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = user2.policies

    result = Policy.check_all action, resource, policies, user2
    result.should eq([institution])
  end

  it "disallows delegable" do
    user2 = User.make

    user3 = User.make

    # user gives user2 permission to read institution
    definition = %({
                      "statement":  [
                        {
                          "effect": "allow",
                          "action": [
                            "#{Policy::READ_INSTITUTION}"
                          ],
                          "resource": "cdpx:institution/#{institution.id}"
                        }
                      ],
                      "delegable": false
                    }
                  )

    policy = Policy.new
    policy.name = "user2 can read institution"
    policy.definition = JSON.parse definition
    policy.user_id = user2.id
    policy.granter_id = user.id
    policy.save!

    # user2 gives user3 permission to read institution
    policy = Policy.new
    policy.name = "user3 can read institution"
    policy.definition = JSON.parse definition
    policy.user_id = user3.id
    policy.granter_id = user2.id
    policy.save!

    # user3 shouldn't be able to read any institution
    action = Policy::READ_INSTITUTION
    resource = institution
    policies = user3.policies

    result = Policy.check_all action, resource, policies, user3
    result.should be_nil
  end

  it "disallows delegable (1)" do
    user2 = User.make
    user3 = User.make
    user4 = User.make

    definition_delegable = %({
                                "statement":  [
                                  {
                                    "effect": "allow",
                                    "action": [
                                      "#{Policy::READ_INSTITUTION}"
                                    ],
                                    "resource": "cdpx:institution/#{institution.id}"
                                  }
                                ],
                                "delegable": true
                              }
                            )

    definition_not_delegable = %({
                                "statement":  [
                                  {
                                    "effect": "allow",
                                    "action": [
                                      "#{Policy::READ_INSTITUTION}"
                                    ],
                                    "resource": "cdpx:institution/#{institution.id}"
                                  }
                                ],
                                "delegable": false
                              }
                            )

    policy = Policy.new
    policy.name = "user2 can read institution"
    policy.definition = JSON.parse definition_not_delegable
    policy.granter_id = user.id
    policy.user_id = user2.id
    policy.save!

    policy = Policy.new
    policy.name = "user3 can read institution"
    policy.definition = JSON.parse definition_delegable
    policy.granter_id = user.id
    policy.user_id = user3.id
    policy.save!

    policy = Policy.new
    policy.name = "user4 can read institution"
    policy.definition = JSON.parse definition_delegable
    policy.granter_id = user3.id
    policy.user_id = user4.id
    policy.save!

    policy = Policy.new
    policy.name = "user4 can read institution"
    policy.definition = JSON.parse definition_delegable
    policy.granter_id = user2.id
    policy.user_id = user4.id
    policy.save!

    # user4 should be able to read institution
    action = Policy::READ_INSTITUTION
    resource = institution
    policies = user4.policies

    result = Policy.check_all action, resource, policies, user4
    result.should eq([institution])
  end
end
