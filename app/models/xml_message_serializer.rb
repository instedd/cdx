# Custom serialization of Nokogiri nodes to trivial data structures, that are
# easy to serialize to another language, such as JavaScript, as used in
# `ManifestFieldMapping#run_script` for example.

class Nokogiri::XML::Attr
  def cdx_name_with_nsprefix
    if namespace
      "#{namespace.prefix}:#{name}"
    else
      name
    end
  end

  def cdx_serializable_hash
    { "name" => cdx_name_with_nsprefix, "value" => value }
  end
end

class Nokogiri::XML::CDATA
  def cdx_serializable_hash
    content
  end
end

class Nokogiri::XML::Document
  def cdx_serializable_hash
    root.cdx_serializable_hash
  end
end

class Nokogiri::XML::Element
  def cdx_serializable_hash
    hsh = { "name" => name }

    unless attribute_nodes.empty?
      hsh["attributes"] = attribute_nodes
        .each_with_object({}) { |attr, h| h[attr.cdx_name_with_nsprefix] = attr.value }
    end

    unless children.empty?
      hsh["children"] = children
        .map { |node| node.cdx_serializable_hash if node.respond_to?(:cdx_serializable_hash) }
        .compact
    end

    hsh
  end
end

class Nokogiri::XML::NodeSet
  def cdx_serializable_hash
    to_a
      .map { |node| node.cdx_serializable_hash if node.respond_to?(:cdx_serializable_hash) }
      .compact
  end
end

class Nokogiri::XML::Text
  def cdx_serializable_hash
    content
  end
end
