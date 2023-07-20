module AutocompleteFieldHelper
  def autocomplete_field(f, name, field_name, institution, **attributes)
    class_name = attributes.delete(:class)
    props = attributes.merge(
      name: name,
      value: f.object.public_send(field_name),
      url: institution_autocomplete_path(institution_id: institution.id, field_name: field_name),
      combobox: true
    )
    props[:className] = class_name if class_name
    react_component("CdxSelectAutocomplete", props)
  end
end
