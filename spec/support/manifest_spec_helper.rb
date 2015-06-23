module ManifestSpecHelper

  def manifest_from_json_mappings(mappings_json, source="json")
    Manifest.new(definition: %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"],
        "source" : {"type" : "#{source}"}
      },
      "field_mapping": #{mappings_json}
    }})
  end

  def assert_manifest_application(mappings_json, format_data, expected_fields={}, device= nil)
    format_data = {json: format_data} unless format_data.kind_of?(Hash)

    expected = {
      test:    { indexed: {}, custom: {}, pii: {} },
      sample:  { indexed: {}, custom: {}, pii: {} },
      patient: { indexed: {}, custom: {}, pii: {} },
      device:  { indexed: {}, custom: {}, pii: {} }
    }.deep_merge(expected_fields).recursive_stringify_keys!

    format_data.each do |format, data|
      manifest = manifest_from_json_mappings(mappings_json, format)
      result = manifest.apply_to(data, device).first
      result.should eq(expected), "Result in format #{format} does not match expected value"
    end
  end

  def assert_raises_manifest_data_validation(mappings_json, data, message, device=nil)
    manifest = manifest = manifest_from_json_mappings(mappings_json)
    expect { manifest.apply_to(data, device).first }.to raise_error(message)
  end

  def default_manifest_for(device)
    Manifest.create! definition: default_definition(device.model)
  end

  def self.default_definition(device_model)
    core_mapping = {}

    Cdx.core_field_scopes.each do |scope|
      map(scope.fields).flatten.each do |field_definition|
        scoped_field_definition = "#{scope.name}#{PATH_SPLIT_TOKEN}#{field_definition}"
        core_mapping[scoped_field_definition] = {
          lookup: scoped_field_definition
        }
      end
    end

    Oj.dump({
      metadata: { source: { type: "json" } }, device_models: [device_model]},
      field_mapping: core_mapping
    })
  end

  def self.map fields, source_prefix = ''
    fields.map do |field|
      if field.nested?
        map field.sub_fields, "#{source_prefix}#{field.name}#{COLLECTION_SPLIT_TOKEN}"
      else
        "#{source_prefix}#{field.name}"
      end
    end
  end
end
