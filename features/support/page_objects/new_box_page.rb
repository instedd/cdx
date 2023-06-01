class NewBoxPage < CdxPageBase
  class BoxBatchSummary < SitePrism::Section
    element :batch_number, ".items-item"
    element :concentration, ".items-concentration"
    element :remove_button, "a[title='Remove this batch']"
    element :open_button, "a .icon-keyboard-arrow-down"
  end

  class SampleSummary < SitePrism::Section
    element :uuid, ".items-item span:first-child"
    element :batch_number, ".items-item span:last-child"
    element :concentration, ".items-concentration"
    element :remove_button, "a[title='Remove this sample']"
  end

  class BoxBatchForm < SitePrism::Section
    element :distractor, "label", text: "Distractor"
    element :instruction, "label", text: "Instruction"

    elements :replicate_fields, "input[name$='[replicate]']"
    elements :concentration_fields, "input[name$='[concentration]']"
    element :add_concentration, ".add-items", text: "ADD CONCENTRATION"
    elements :remove_concentrations, ".box-batch-form-concentrations .icon-delete"

    element :ok, ".btn-primary"
  end

  set_url "/boxes/new"

  element :errors, ".form-errors"

  section :purpose_field, CdxSelect, "label", text: /Purpose/i
  section :media_field, CdxSelect, "label", text: /Media/i

  element :add_batches, "label[for='box_option_add_batches']"
  element :add_batch_button, ".add-link", text: "ADD BATCH"
  element :batches_selector, ".batches-selector"
  section :search_batch, CdxSelect, ".batches-selector .Select"
  sections :batch_summaries, BoxBatchSummary, ".box-batch-summary"
  sections :batch_forms, BoxBatchForm, ".box-batch-form"

  element :add_samples, "label[for='box_option_add_samples']"
  element :add_sample_button, ".add-link", text: "ADD SAMPLE"
  element :samples_selector, ".samples-selector"
  section :search_sample, CdxSelect, ".samples-selector .Select"
  sections :sample_summaries, SampleSummary, ".sample-summary"

  element :add_csv, "label[for='box_option_add_csv']"
  element :add_csv_button, ".add-link", text: "ADD CSV"
  element :csv_box, :field, 'box[csv_box]'


  element :submit_button, :button, "Save"

  def fill(purpose: nil, media: nil, option: nil)
    purpose_field.set(purpose) if purpose
    media_field.set(media) if media

    case option.to_s
    when "add_batches"
      add_batches.click
      wait_until_batches_selector_visible
    when "add_samples"
      add_samples.click
      wait_until_samples_selector_visible
    when "add_csv"
      add_csv.click
    end
  end

  def add_batch(batch, distractor: false, instruction: nil, concentrations: [])
    add_batch_button.click unless has_search_batch?(wait: 0)
    search_batch.type_and_select(batch.batch_number)

    batch_forms.last.tap do |form|
      form.distractor.click if distractor
      form.instruction.set(instruction) if instruction

      concentrations.each_with_index do |(replicate, concentration), index|
        form.add_concentration.click if index > 0
        form.replicate_fields.last.set(replicate)
        form.concentration_fields.last.set(concentration)
      end
      form.ok.click
    end
  end

  def add_sample(sample)
    add_sample_button.click unless has_search_sample?(wait: 0)
    search_sample.paste(sample.uuid)
  end

  def add_csv_file(csv_filename)
    attach_file('box[csv_box]', Rails.root.join('spec/fixtures/csvs', csv_filename), make_visible: true)
  end

  def submit
    submit_button.click
  end
end

# Identical to NewBoxPage except that the URL is POST /boxes
# instead of GET /boxes/new
class CreateBoxPage < NewBoxPage
  set_url "/boxes"
end

class ListBoxesPage < CdxPageBase
  class BoxEntry < SitePrism::Section
    element :checkbox,      "td:nth-child(1) input"
    element :uuid,          "td:nth-child(2)"
    element :purpose,       "td:nth-child(3)"
    element :samples_count, "td:nth-child(4)"
    element :created_at,    "td:nth-child(5)"
  end

  set_url "/boxes"

  sections :entries, BoxEntry, "tr.laboratory-sample-row"
end

class ShowBoxPage < CdxPageBase
  set_url "/boxes/{id}"

  elements "samples", ".box-sample-row"
end
