class JsonEventParser
  def lookup(path, data)
    if (targets = path.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1

      #TODO recursive lookup
      paths = targets.first.split Manifest::PATH_SPLIT_TOKEN

      elements_array = paths.inject data do |current, path|
        current[path] || []
      end
      ######################
      elements_array.map do |element|
        lookup(targets.drop(1).join(Manifest::COLLECTION_SPLIT_TOKEN), element)
      end
    else
      paths = path.split Manifest::PATH_SPLIT_TOKEN
      paths.inject data do |current, path|
        current[path] if current.is_a? Hash
      end
    end
  end

  def load(data)
    Array.wrap(Oj.load(data))
  end
end
