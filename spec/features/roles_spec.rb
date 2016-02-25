require 'spec_helper'

describe "roles", elasticsearch: true do
  let!(:institution) { Institution.make }
  let!(:user) { institution.user }
  let!(:site) { institution.sites.make }

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
end
