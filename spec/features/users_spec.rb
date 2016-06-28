require 'spec_helper'
require 'policy_spec_helper'

describe "Users", elasticsearch: true do
  let!(:institution) { Institution.make }
  let!(:user) { institution.user }
  let!(:foo_user) { User.make } 
  let!(:bar_user) { User.make }
  let!(:role) { Role.first }
  let!(:second_role) { Role.second }
  
  context "filters" do   
    before(:each) {
      foo_user.roles << role
      bar_user.roles << role
      sign_in(user)
    }

    it "should filter users by name", testrail: 471 do
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

  context "user view" do
    let!(:my_user) { institution.user }
    
    before(:each) {
      my_user.roles << role
      sign_in(user)
    }

    it "should replace user role", testrail: 449 do
      goto_page UsersPage do |page|
        page.table.items.first.click
      end

      expect_page UserEditPage do |page|
        expect(page).to have_content(role.name)
        page.find(".remove").click
        expect(page).to_not have_content(role.name)
        page.add_role.click
        fill_in  "Search", :with => second_role.name
        page.autocomplete.click
      end 

      goto_page UsersPage do |page|
        page.table.items.first.click
      end

      expect_page UserEditPage do |page|
        expect(page).to have_content(second_role.name)
      end  
    end
  end

end
