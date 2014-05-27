require 'spec_helper'

describe Policy do
  let!(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }

  it "doesn't allow a user to list his institutions without the implicit policy" do
    action = "cdpx:list_institutions"
    resource = Institution
    policies = []

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_false
    result.resources.should eq(nil)
  end

  it "allows a user to list his institutions" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = "cdpx:list_institutions"
    resource = Institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution])
  end

  it "allows a user to edit his institution" do
    action = "cdpx:edit_institution"
    resource = institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution])
  end

  it "doesn't allows a user to edit an instiutiton he is not an owner of" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = "cdpx:edit_institution"
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
                                              "cdpx:readInstitution",
                                              "cdpx:updateInstitution"
                                            ],
                                            "resource": "cdpx:institution/#{institution2.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    action = "cdpx:readInstitution"
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
                                              "cdpx:readInstitution",
                                              "cdpx:updateInstitution"
                                            ],
                                            "resource": "cdpx:institution/#{institution3.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    action = "cdpx:readInstitution"
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
                                              "cdpx:readInstitution",
                                              "cdpx:updateInstitution"
                                            ],
                                            "resource": "cdpx:institution/#{institution2.id}"
                                          }
                                        ],
                                        "delegable": true
                                      }
                                    )
    action = "cdpx:readInstitution"
    resource = Institution
    policies = [policy]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution2])
  end
end
