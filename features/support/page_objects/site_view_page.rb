class SiteViewPage < CdxPageBase
  set_url '/sites{/site_id}/{?query*}'

  section :tabs, '.tabs' do
    element :users, :link, 'Users'
  end
end

class SiteEditPage < CdxPageBase
  set_url '/sites{/site_id}/edit{?query*}'

  def shows_deleted?
    page.has_css?('h2.deleted')
  end

  section :parent_site, CdxSelect, "label", text: /Parent site/i
end
