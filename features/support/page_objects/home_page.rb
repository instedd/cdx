class HomePage < SitePrism::Page
  set_url '/'

  element :sign_in, :link, "Sign in", match: :first
end
