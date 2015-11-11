class NewDeviceModelPage < CdxPageBase
  set_url "/device_models/new"

  element :name, :field, "Name"
  section :supports_activation, CdxCheckbox, "label", text: "Supports activation"
  element :support_url, :field, "Support url"
  section :manifest, FileInput, :field, "Manifest"
end
