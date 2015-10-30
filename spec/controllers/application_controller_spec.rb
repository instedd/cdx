require 'spec_helper'
require 'policy_spec_helper'

describe ApplicationController do
  let(:user) { User.make }
  
  it "redirects to admin for MANAGE USER role" do
  #   grant user, User, MANAGE_USER
   user.grant_superadmin_policy
   sign_in user
   expect(controller.after_sign_in_path_for(user)).to eq '/admin'
  end
  
  it "does not redirect to admin for non MANAGE USER role" do
   sign_in user
   expect(controller.after_sign_in_path_for(user)).to eq '/'
  end
  
end
