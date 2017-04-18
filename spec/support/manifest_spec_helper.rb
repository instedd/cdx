module ManifestSpecHelper

  def manifest_from_json_mappings(mappings_json, custom_json = '{}', source="json")
    Manifest.new(device_model: DeviceModel.new(name:"GX4001"), definition: %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "#{Manifest::CURRENT_VERSION}",
        "conditions": ["mtb"],
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
      expect(result).to eq(expected), "Result in format #{format} does not match expected value"
    end
  end

  def assert_raises_manifest_data_validation(mappings_json, custom_json, data, message, device=nil)
    manifest = manifest = manifest_from_json_mappings(mappings_json, custom_json)
    expect { manifest.apply_to(data, device).first }.to raise_error(message)
  end

  def load_manifest(name, device_model)
    definition = IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', name))
    Manifest.create!(device_model: device_model, definition: definition)
  end

  def copy_sample_csv(name, destination)
    copy_sample(name, 'csvs', destination)
  end

  def copy_sample_xml(name, destination)
    copy_sample(name, 'xmls', destination)
  end

  def copy_sample_json(name, destination)
    copy_sample(name, 'jsons', destination)
  end

  def copy_sample(name, format, destination)
    FileUtils.cp File.join(Rails.root, 'spec', 'fixtures', format, name), destination
  end
end
