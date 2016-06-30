require 'spec_helper'

describe "roles", elasticsearch: true do
  let!(:institution) { Institution.make }
  let!(:user) { institution.user }
  let!(:site) { institution.sites.make }
  let!(:role) { Role.first }
  let!(:other_role) { Role.second }

  context "Site owner" do

    before(:each) {
      sign_in(user)
    }

    it "roles have been created for sites and institution" do
      expect(institution.roles.count).to be > 3
      expect(site.roles.count).to be > 0
    end

    it "all built in roles should be listed" do
      goto_page RolesPage do |page|
        expect(page.table.items.count).to eq(institution.roles.count)
      end
    end

    it "all built in roles should be accessible" do
      institution.roles.count.times do |i|
        goto_page RolesPage do |page|
          page.table.items[i].click
        end
      end
    end

    it "should delete role", testrail: 1376 do
      goto_page RolesPage do |page|
        page.table.items.first.click
      end

      expect_page RoleEditPage do |page|
        page.delete.click
        page.confirmation.delete.click
      end

      expect_page RolesPage do |page|  
        expect(page).to_not have_content(role.name)
      end 
    end

    it "should rename role", testrail: 464 do
      goto_page RolesPage do |page|
        expect(page).to have_content(role.name)
        page.table.items.first.click
      end

      expect_page RoleEditPage do |page|
        page.name.set "Renamed_Role"
        page.submit
      end 

      expect_page RolesPage do |page|
        expect(page).to_not have_content(role.name)
        expect(page).to have_content("Renamed_Role")
      end   
    end
  end

  context "site admin" do
    let!(:site_admin) { User.make }

    before(:each) {
      role = site.roles.select{|r| r.name.include?("Admin")}
      site_admin.roles << role
      site_admin.update_computed_policies
      sign_in(site_admin)
    }

    it "should load for site admin", testrail: 1194 do
      goto_page RolesPage do |page|
        expect(page.table.items.count).to eq(site.roles.count)
      end
    end
  end

  context "filters" do   
    before(:each) {
      sign_in(user)
    }

    it "should filter roles by name", testrail: 1112 do
      goto_page RolesPage do |page|
        expect(page).to have_content(role.name)

        page.update_filters do
          fill_in  "name", :with => role.name
        end

        expect(page).to have_content(role.name)
        expect(page).to_not have_content(other_role.name)
      end
    end
  end
end
