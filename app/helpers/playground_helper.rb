module PlaygroundHelper
  def devices_with_specified_field(specified_field)
    devices_and_results = {}
    devices = Device.all
    devices.each do |d|
      field_mappings = Oj.load(d.device_model.manifests.last.definition)["field_mapping"]
      devices_and_results["#{d.secret_key}"] = {}
      results = field_mappings.detect {|f| f["target_field"] == specified_field}["options"]
      devices_and_results["#{d.secret_key}"]["original"] = results
      devices_and_results["#{d.secret_key}"]["titleized"] = results.map &:titleize
    end
    devices_and_results
  end

  def result_and_condition
    fields_with_dictionaries = {}
    fields_with_dictionaries["result"] = devices_with_specified_field("results[*].result")
    fields_with_dictionaries["condition"] = devices_with_specified_field("results[*].condition")
    fields_with_dictionaries["assay_name"] = devices_with_specified_field("assay_name")
    fields_with_dictionaries["gender"] = devices_with_specified_field("gender")
    fields_with_dictionaries
  end

end

