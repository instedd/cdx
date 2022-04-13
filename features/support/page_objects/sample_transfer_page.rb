class ListSampleTransfersPage < CdxPageBase
  set_url "/sample_transfers"

  class SampleTransferEntry < SitePrism::Section
    element :uuid, "td:first-child"
    element :state, "td:last-child"

    element :confirm, :link, "Confirm receipt"
  end

  section :filters, "#filters-form" do
    element :sample_id, :field, "Sample ID"
    element :batch_number, :field, "Batch Number"
    element :isolate_name, :field, "Isolate Name"
    element :specimen_role, :field, "Specimen Role"

    include CdxPageHelper
  end

  sections :entries, SampleTransferEntry, ".laboratory-sample-row"

  def entry(uuid)
    SampleTransferEntry.new(self, find("tr", text: uuid))
  end

  section :confirm_receipt_modal, ".modal" do
    element :uuid_check, :field, "Sample ID"
    element :submit_button, :button, "Confirm"

    def submit
      submit_button.click
    end
  end
end
