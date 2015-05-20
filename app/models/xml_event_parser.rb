class XmlEventParser
  def lookup(path, data)
    results = data.xpath(path).map(&:content)
    results.size == 1 ? results.first : results
  end

  def load(data)
    Nokogiri::XML(data) do |config|
      config.noblanks.strict
    end.root.children
  end
end
