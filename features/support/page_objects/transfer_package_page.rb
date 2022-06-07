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

class ListTransferPackagesPage < CdxPageBase
  set_url "/transfer_packages"

  class TransferEntry < SitePrism::Section
    element :uuid, "td.col-uuid"
    element :transfer_date, "td.col-transfer_date"
    element :origin, "td.col-origin"
    element :destination, "td.col-destination"
    element :recipient, "td.col-recipient"
    element :state, "td.col-state"
  end

  section :filters, "#filters-form" do
    element :sample_id, :field, "Sample ID"
    element :batch_number, :field, "Batch Number"
    element :isolate_name, :field, "Isolate Name"
    element :specimen_role, :field, "Specimen Role"

    include CdxPageHelper
  end

  sections :entries, TransferEntry, "tr.transfer_package-row"

  def entry(uuid)
    TransferEntry.new(self, find("tr.transfer_package-row", text: uuid))
  end
end

class ShowTransferPackagePage < CdxPageBase
  set_url "/transfer_packages/{id}"

  element :confirm_button, :button, "Confirm"
end
