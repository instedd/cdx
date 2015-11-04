class HomePage < SitePrism::Page
  set_url '/'

  element :sign_in, "a[href='/users/sign_in']:first-child"
end
