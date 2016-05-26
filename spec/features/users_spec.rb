require 'spec_helper'
require 'policy_spec_helper'

describe "Users", elasticsearch: true do
  let!(:institution) { Institution.make }
  let!(:user) { institution.user }
  let!(:foo_user) { User.make } 
  let!(:bar_user) { User.make }
  let!(:role) { Role.first }
  
  context "filters" do   
    before(:each) {
      foo_user.roles << role
      bar_user.roles << role
      sign_in(user)
    }

    it "should filter users by name" do
      goto_page UsersPage do |page|
        expect(page).to have_content(foo_user.first_name)

        page.update_filters do
          fill_in  "name", :with => foo_user.first_name
        end

        expect(page).to have_content(foo_user.last_name)
        expect(page).to_not have_content(bar_user.last_name)
      end
    end
  end

end
