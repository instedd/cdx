class PolicyPage < SitePrism::Page
  set_url '/policies/new'

  section 'form', '#new_policy' do
    element :email, '#policy_user_id'
    element :name, '#policy_name'
    element :policy, '#policy_definition'
    element :invite, '[name="commit"]'
  end
end
