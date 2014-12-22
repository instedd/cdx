class ManifestFieldMapping
  def initialize(manifest, field)
    @manifest = manifest
    @field = field
    @source = @field["source"]
  end

  def map(value, mappings)
    return value unless mappings && value

    matched_mapping = mappings.detect do |field|
      value.match field["match"].gsub("*", ".*")
    end

    if matched_mapping
      matched_mapping["output"]
    else
      raise ManifestParsingError.new "'#{value}' is not a valid value for '#{@target_field}' (valid value must be in one of these forms: #{mappings.map(){|f| f["match"]}.join(", ")})"
    end
  end

  def parse(path, data)
    @manifest.parser.parse(path, data)
  end

  def apply_to(data)
    traverse @source, data
  end

  def traverse node, data
    case identify node
    when "path"
      parse(node["path"], data)
    when "mapping"
      map(traverse(node["mapping"][0], data), node["mapping"][1])
    when "concat"
      node["concat"].map do |source|
        traverse(source, data)
      end.join
    when "strip"
      traverse(node["strip"], data).strip
    when "days_in"
      node
    else
      node
    end
  end

  def identify node
    return node.to_s unless node.is_a? Hash

    return "path" if node["path"].present?
    return "mapping" if node["mapping"].present?
    return "concat" if node["concat"].present?
    return "days_in" if node["days_in"].present?
    return "strip" if node["strip"].present?

    ""
  end
end
