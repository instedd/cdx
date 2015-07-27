module ManifestSpecHelper

  def manifest_from_json_mappings(mappings_json, custom_json = '[]', source="json")
    Manifest.new(definition: %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "#{Manifest::CURRENT_VERSION}",
        "device_models" : ["GX4001"],
        "conditions": ["MTB"],
        "source" : {"type" : "#{source}"}
      },
      "custom_fields": #{custom_json},
      "field_mapping": #{mappings_json}
    }})
  end

  def assert_manifest_application(mappings_json, custom_json, format_data, expected_fields={}, device= nil)
    format_data = {json: format_data} unless format_data.kind_of?(Hash)

    expected = Manifest.new_message.deep_merge(expected_fields)

    format_data.each do |format, data|
      manifest = manifest_from_json_mappings(mappings_json, custom_json, format)
      result = manifest.apply_to(data, device).first
      result.should eq(expected), "Result in format #{format} does not match expected value"
    end
  end

  def assert_raises_manifest_data_validation(mappings_json, custom_json, data, message, device=nil)
    manifest = manifest = manifest_from_json_mappings(mappings_json, custom_json)
    expect { manifest.apply_to(data, device).first }.to raise_error(message)
  end
end
