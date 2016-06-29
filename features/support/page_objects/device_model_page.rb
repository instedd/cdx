class NewDeviceModelPage < CdxPageBase
  set_url "/device_models/new"

  element :name, :field, "Name"
  section :supports_activation, CdxCheckbox, "label", text: /Supports activation/i
  element :support_url, :field, "Support url"
  section :manifest, FileInput, :field, "Manifest"
end

class DeviceModelPage < CdxPageBase
  set_url "/device_models/{id}/edit"

  element :name, :field, "Name"
  element :support_url, :field, "Support url"
  section :manifest, FileInput, :field, "Manifest"
end

class DeviceModelsPage < CdxPageBase
  set_url "/device_models"

  section :table, CdxTable, "table"
end
