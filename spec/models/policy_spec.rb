require 'spec_helper'

describe Policy do
  let!(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }

  it "doesn't allow a user to list his institutions without the implicit policy" do
    action = "cdp:list_institutions"
    resource = Institution
    policies = []

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_false
    result.resources.should eq(nil)
  end

  it "allows a user to list his institutions" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = "cdp:list_institutions"
    resource = Institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution])
  end

  it "allows a user to edit his institution" do
    action = "cdp:edit_institution"
    resource = institution
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_true
    result.resources.should eq([institution])
  end

  it "doesn't allows a user to edit an instiutiton he is not an owner of" do
    user2 = User.make
    institution2 = user2.create Institution.make_unsaved

    action = "cdp:edit_institution"
    resource = institution2
    policies = [Policy.implicit]

    result = Policy.check_all action, resource, policies, user
    result.allowed?.should be_false
    result.resources.should eq(nil)
  end
end
