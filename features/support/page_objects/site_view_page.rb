class SiteEditPage < CdxPageBase
  set_url '/sites{/site_id}/edit{?query*}'

  element :delete, :link, 'Delete'

  def shows_deleted?
    page.has_css?('h2.deleted')
  end

  section :parent_site, CdxSelect, "label", text: /Parent site/i
end
