class RolesPage < CdxPageBase
  set_url "/roles"

  section :table, CdxTable, "table"
end

class RoleEditPage < CdxPageBase
  set_url '/roles{/role_id}/edit{?query*}'

  element :delete, :link, 'Delete'
  element :name, :field, "Name"
end