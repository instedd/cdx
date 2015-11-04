require 'spec_helper'

describe "the login process", :type => :feature, :js => true do
  it "existing user can login" do
    user = User.make institutions: [Institution.make]

    goto_page HomePage do |page|
      page.sign_in.click
    end

    expect_page LoginPage do |page|
      page.form.user_name.set user.email
      page.form.password.set user.password
      page.form.login.click
    end

    expect(page).to have_content 'Signed in successfully'

    # screenshot_and_open_image
  end

  def goto_page(klass)
    page = klass.new
    page.load
    yield page
  end

  def expect_page(klass)
    page = klass.new
    expect(page).to be_displayed
    yield page
  end
end
