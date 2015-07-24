class DefaultManifest
  def self.for(device_model_name)
    Manifest.create! definition: definition(device_model_name)
  end

  def self.definition(device_model_name)
    core_mapping = {}

    Cdx.core_field_scopes.each do |scope|
      map(scope.fields).flatten.each do |field_definition|
        scoped_field_definition = "#{scope.name}#{Manifest::PATH_SPLIT_TOKEN}#{field_definition}"
        core_mapping[scoped_field_definition] = {
          lookup: scoped_field_definition
        }
      end
    end

    Oj.dump({
      metadata: {
        source: { type: "json" },
        device_models: [device_model_name],
        api_version: "#{Manifest::CURRENT_VERSION}",
        conditions: ["MTB"],

        version: "0.0.1"
      },
      field_mapping: core_mapping
    })
  end

  def self.map fields, source_prefix = ''
    fields.map do |field|
      if field.nested?
        map field.sub_fields, "#{source_prefix}#{field.name}#{Manifest::COLLECTION_SPLIT_TOKEN}"
      else
        "#{source_prefix}#{field.name}"
      end
    end
  end
end
