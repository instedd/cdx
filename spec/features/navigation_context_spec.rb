require 'spec_helper'

describe "navigation context" do
  let(:institution) { Institution.make }
  let(:user) { institution.user }
  before(:each) { sign_in(user) }

  it "user without context history shold get the institution as context" do
    goto_page HomePage
    user.reload
    expect(page).to have_content(institution.name)
    expect(user.last_navigation_context).to eq(institution.uuid)
  end

  it "user get last context by default" do
    other_institution = Institution.make user: user
    goto_page HomePage do |page|
      # Context panel is now open by default
      page.get_context_picker do |context|
        context.select other_institution.name
      end

      page.close_context_picker
      # This saves the picker as closed, when loading again other_institution should not be there
    end

    user.reload
    expect(user.last_navigation_context).to eq(other_institution.uuid+"-*")

    goto_page HomePage do |page|
      expect(page).to have_content(other_institution.name)
      expect(page).to_not have_content(institution.name)
    end
  end

  it "user is get back to a safe context if permission changed" do
    other_institution = Institution.make
    user.update_attribute :last_navigation_context, other_institution.uuid

    goto_page HomePage

    expect(page).to have_content(institution.name)
    user.reload
    expect(user.last_navigation_context).to eq(institution.uuid)
  end
end
