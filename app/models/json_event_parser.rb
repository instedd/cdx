class JsonEventParser
  def apply_selector(selector, data)
    if (targets = selector.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1

      paths = targets.first.split Manifest::PATH_SPLIT_TOKEN

      elements_array = paths.inject data do |current, path|
        current[path] || []
      end
      elements_array.map do |element|
        paths = targets.last.split Manifest::PATH_SPLIT_TOKEN
        paths.inject element do |current, path|
          current[path]
        end
      end
    else
      paths = selector.split Manifest::PATH_SPLIT_TOKEN
      paths.inject data do |current, path|
        current[path] if current.is_a? Hash
      end
    end
  end

  def load(data)
    Oj.load data
  end
end
