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

    it "should filter sites by name" do
      goto_page SitesPage do |page|

        within filters do
          fill_in  "name", :with => foo_site.name
        end

        expect(page).to have_content(foo_site.id)
        expect(page).to_not have_content(bar_site.id)
      end
    end
  end
end
