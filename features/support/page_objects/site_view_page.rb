class SiteViewPage < CdxPageBase
  set_url '/sites{/site_id}'

  section :tabs, '.tabs' do
    element :users, :link, 'Users'
  end
end
