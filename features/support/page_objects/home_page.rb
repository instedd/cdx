class HomePage < CdxPageBase
  set_url '/'

  element :sign_in, :link, "Sign in", match: :first
end
