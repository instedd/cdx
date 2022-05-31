class NewTransferPackagePage < CdxPageBase
  set_url "/transfer_packages/new"

  class BoxTransferPreview < SitePrism::Section
    element :box_uuid, ".box__uuid"
  end

  section :destination, CdxSelect, "label", text: /Destination/i
  element :recipient, :field, "Recipient"

  sections :boxes_list, BoxTransferPreview, ".box-preview"

  def selected_box_uuids
    boxes_list.map { |preview| preview.box_uuid.text }
  end

  element :box_search, :field, "Enter, paste or scan box ID"

  element :submit_button, :button, "Transfer"

  def submit
    submit_button.click
  end
end
