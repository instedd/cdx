require 'spec_helper'

describe Policy do
  let!(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }

  it "doesn't allow a user to read his institutions without the implicit policy" do
    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = []

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_false
    result.resources.should eq(nil)
  end

  it "allows a user to read his institutions" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = Policy::READ_INSTITUTION
    resource = Institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution])
  end

  it "allows a user to update his institution" do
    action = Policy::UPDATE_INSTITUTION
    resource = institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution])
  end

  it "doesn't allows a user to update an instiutiton he is not an owner of" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = Policy::UPDATE_INSTITUTION
    resource = institution2
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_false
    result.resources.should eq(nil)
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
    result.allowed?.should be_true
    result.resources.should eq([institution2])
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
    result.allowed?.should be_false
    result.resources.should be_nil
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
    result.allowed?.should be_true
    result.resources.should eq([institution2])
  end
end
