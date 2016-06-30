require 'spec_helper'

describe "the login process" do
  let(:user) {User.make institutions: [Institution.make]}

  it "existing user can login", testrail: 481 do   
    goto_page HomePage do |page|
      page.form.user_name.set user.email
      page.form.password.set user.password
      page.form.login.click
    end

    expect(page).to have_content 'Signed in successfully'
  end

  context "when logged in" do
  	before(:each) {
	  	sign_in(user)
  	}
	
  	it "can logout" do
      goto_page HomePage do |page|
        page.logout
      end

      expect(page).to have_content 'Signed out successfully'
    end
  end
end
