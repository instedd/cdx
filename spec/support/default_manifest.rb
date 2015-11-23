class DefaultManifest
  def self.for
    Manifest.create! definition: definition
  end

  def self.definition
    core_mapping = {}

    Cdx::Fields.entities.core_field_scopes.each do |scope|
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
        api_version: "#{Manifest::CURRENT_VERSION}",
        conditions: ["mtb"],

        version: "0.0.1"
      },
      field_mapping: core_mapping
    })
  end

  def self.map fields, source_prefix = ''
    fields.map do |field|
      if field.nested?
        map field.sub_fields, "#{source_prefix}#{field.name}#{Manifest::PATH_SPLIT_TOKEN}"
      else
        "#{source_prefix}#{field.name}"
      end
    end
  end
end
