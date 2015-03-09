module ManifestSpecHelper

  def manifest_from_json_mappings(mappings_json)
    Manifest.new(definition: "{\"metadata\":{\"source\" : {\"type\" : \"json\"}},\"field_mapping\" : #{mappings_json}}")
  end

  def assert_manifest_application(mappings_json, data, expected)
    manifest = manifest_from_json_mappings(mappings_json)
    result = manifest.apply_to(data)
    expected = {
      event:   { indexed: {}, custom: {}, pii: {} },
      sample:  { indexed: {}, custom: {}, pii: {} },
      patient: { indexed: {}, custom: {}, pii: {} },
    }.deep_merge(expected)

    result.should eq(expected.recursive_stringify_keys!)
  end

  def assert_raises_manifest_data_validation(mappings_json, data, message)
    manifest = manifest = manifest_from_json_mappings(mappings_json)
    expect { manifest.apply_to(data) }.to raise_error(message)
  end

end
