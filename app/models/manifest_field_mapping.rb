class ManifestFieldMapping
  def initialize(manifest, field)
    @manifest = manifest
    @field = field
  end

  def apply_to(data)
    traverse @field["source"], data
  end

  def traverse node, data
    if node["lookup"].present?
      return lookup(node["lookup"], data)
    end

    if node["map"].present?
      return map(traverse(node["map"][0], data), node["map"][1])
    end

    if node["concat"].present?
      return node["concat"].map do |source|
        traverse(source, data)
      end.join
    end

    if node["strip"].present?
      return traverse(node["strip"], data).strip
    end

    if node["convert_time"].present?
      return convert_time(traverse(node["convert_time"][0], data), node["convert_time"][1], node["convert_time"][2])
    end

    if node["beginnin_of"].present?
      return beginning_of(traverse(node["beginning_of"][0], data), node["beginning_of"][1])
    end

    if node["milliseconds_between"].present?
     return milliseconds_between(traverse(node["milliseconds_between"][0], data), traverse(node["milliseconds_between"][1], data))
    end

    if node["clusterise"].present?
      return clusterise(traverse(node["clusterise"][0], data), traverse(node["clusterise"][1], data))
    end

    if node["substring"].present?
      return traverse(node["substring"][0], data)[node["substring"][1]..node["substring"][2]]
    end

    node.to_s
  end

  def map(value, mappings)
    return value unless value

    mapping = mappings.detect do |mapping|
      value.match mapping["match"].gsub("*", ".*")
    end

    raise ManifestParsingError.invalid_mapping(value, @field['target_field'], mappings) unless mapping

    mapping["output"]
  end

  def lookup(path, data)
    @manifest.parser.lookup(path, data)
  end

  def convert_time
  end

  def beginning_of
  end

  def milliseconds_between
  end

  def clusterise
  end
end
