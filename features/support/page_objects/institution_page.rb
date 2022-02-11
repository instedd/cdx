class InstitutionNewFromInvitePage < CdxPageBase
  set_url '/institutions/new_from_invite_data{?query*}'

  element :name, :field, "Name"
end
