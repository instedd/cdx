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
    when "lookup"
      parse(node["lookup"], data)
    when "map"
      map(traverse(node["map"][0], data), node["map"][1])
    when "concat"
      node["concat"].map do |source|
        traverse(source, data)
      end.join
    when "strip"
      traverse(node["strip"], data).strip
    when "convert_time"
      traverse(node["convert_time"], data).to_s
    else
      node.to_s
    end
  end

  def identify node
    return node unless node.is_a? Hash

    return "lookup" if node["lookup"].present?
    return "map" if node["map"].present?
    return "concat" if node["concat"].present?
    return "convert_time" if node["convert_time"].present?
    return "strip" if node["strip"].present?

    ""
  end
end
