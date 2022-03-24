class InstitutionNewFromInvitePage < CdxPageBase
  set_url '/institutions/new{?query*}'

  element :name, :field, "Name"
end
