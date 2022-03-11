class ListSampleTransfersPage < CdxPageBase
  set_url "/sample_transfers"

  section :filters, "#filters-form" do
    element :sample_id, :field, "Sample ID"
    element :batch_number, :field, "Batch Number"
    element :isolate_name, :field, "Isolate Name"
    element :specimen_role, :field, "Specimen Role"

    include CdxPageHelper

    def submit
      root_element.native.send_keys :enter
      wait_for_submit
    end
  end

  def entry(uuid)
    find("tr", text: uuid)
  end

  section :confirm_receipt_modal, ".modal" do
    element :uuid_check, :field, "Sample ID"
    element :submit_button, :button, "Confirm"

    def submit
      submit_button.click
    end
  end
end
