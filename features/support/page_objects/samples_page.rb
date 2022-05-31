class ListSamplesPage < CdxPageBase
  set_url "/samples"

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

  section :actions, ".table-actions" do
  end
end
