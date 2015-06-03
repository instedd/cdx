class XmlEventParser
  def lookup(path, data, root = data)
    if path.starts_with? "/"
      results = root.xpath(path[1..-1])
    else
      results = data.xpath(path)
    end
    results = results.map do |node|
      case node.type
      when Nokogiri::XML::Node::TEXT_NODE
        node.text
      when Nokogiri::XML::Node::ATTRIBUTE_NODE
        node.value
      else
        node
      end
    end
    results.size == 1 ? results.first : results
  end

  def load(data)
    Nokogiri::XML(data) do |config|
      config.noblanks.strict
    end.root.children
  end
end
