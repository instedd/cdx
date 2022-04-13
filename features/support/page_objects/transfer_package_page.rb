class NewTransferPackagePage < CdxPageBase
  set_url "/transfer_packages/new"

  class SampleTransferPreview < SitePrism::Section
    element :sample_uuid, ".sample__uuid"
  end

  section :institution, CdxSelect, "label", text: /Institution/i
  element :recipient, :field, "Recipient"

  sections :samples_list, SampleTransferPreview, ".sample-transfer-preview"

  def selected_sample_uuids
    samples_list.map { |preview| preview.sample_uuid.text }
  end

  element :sample_search, :field, "Enter, paste or scan sample ID"

  element :submit_button, :button, "Transfer"

  def submit
    submit_button.click
  end
end
