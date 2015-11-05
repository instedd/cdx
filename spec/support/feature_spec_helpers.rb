module FeatureSpecHelpers
  extend ActiveSupport::Concern

  included do
    metadata[:js] = true
  end

  def sign_in(user)
    if user.password.nil?
      # change password of user
      user.password = 'password'
      user.password_confirmation = 'password'
      user.save!
    end

    goto_page LoginPage do |page|
      page.form.user_name.set user.email
      page.form.password.set user.password
      page.form.login.click
    end
  end

  def goto_page(klass, args = {})
    page = klass.new
    page.load args
    yield page
  end

  def expect_page(klass)
    page = klass.new
    expect(page).to be_displayed
    yield page
  end

  def snapshot
    screenshot_and_open_image
  end
end
