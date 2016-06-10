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

    before(:each) {
      sign_in(user)
    }

    it "should add site", testrail: 398 do
      goto_page SitesPage do |page|

      click_link "Add Site"
      fill_in  "site[name]", :with => "Vietnam"
      page.submit  


      expect(page).to have_content("Vietnam")
      end
    end
  end
end
