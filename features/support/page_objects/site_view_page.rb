class SiteViewPage < CdxPageBase
  set_url '/sites{/site_id}/{?query*}'

  section :tabs, '.tabs' do
    element :users, :link, 'Users'
  end
end

class SiteEditPage < CdxPageBase
  set_url '/sites{/site_id}/edit{?query*}'

  section :parent_site, CdxSelect, "label", text: /Parent site/i
end
