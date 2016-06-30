require 'spec_helper'
require 'policy_spec_helper'

describe "site" do
  let(:institution) { Institution.make }
  let!(:user) { institution.user }

  context "filters" do
    let!(:foo_site) {institution.sites.make }
    let!(:bar_site) {institution.sites.make }
   
    before(:each) {
      sign_in(user)
    }

    it "should filter sites by name", testrail: 394 do
      goto_page SitesPage do |page|

        page.update_filters do
          fill_in  "name", :with => foo_site.name
        end
        
        expect(page).to have_content(foo_site.location.name)
        expect(page).to_not have_content(bar_site.location.name)
      end
    end
  end

  context "site view" do
    let!(:foo_site) {institution.sites.make }

    before(:each) {
      sign_in(user)
    }

    it "should add site", testrail: 398 do
      goto_page SitesPage do |page|
        click_link "Add Site"
      end

      expect_page SiteNewPage do |page|
        fill_in  "site[name]", :with => "Vietnam"
        page.submit 
        expect(page).to have_content("Vietnam")
      end          
    end

    it "should delete site", testrail: 399 do
      goto_page SitesPage do |page|
        page.table.items.first.click
      end

      expect_page SiteEditPage do |page|
        page.delete.click
        page.confirmation.delete.click
      end

      expect_page SitesPage do |page|  
        expect(page).to_not have_content(foo_site.name)
      end 
    end

    it "should rename site", testrail: 396 do
      goto_page SitesPage do |page|
        expect(page).to have_content(foo_site.name)
        page.table.items.first.click
      end

      expect_page SiteEditPage do |page|
        page.name.set "Renamed_Site"
        page.submit
      end 

      expect_page SitesPage do |page|
        expect(page).to_not have_content(foo_site.name)
        expect(page).to have_content("Renamed_Site")
      end   
    end
  end
end
