class JsonEventParser

  PATH_ROOT_TOKEN = "$"

  def lookup(path, data, root = data)
    if (targets = path.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1

      #TODO recursive lookup
      paths = targets.first.split Manifest::PATH_SPLIT_TOKEN

      elements_array = paths.inject data do |current, path|
        current[path] || []
      end
      ######################
      elements_array.map do |element|
        lookup(targets.drop(1).join(Manifest::COLLECTION_SPLIT_TOKEN), element, root)
      end
    else
      paths = path.split Manifest::PATH_SPLIT_TOKEN
      paths.inject data do |current, path|
        if path == PATH_ROOT_TOKEN
          root
        elsif current.is_a? Hash
          current[path]
        end
      end
    end
  end

  def load(data, root_path = nil)
    data = Oj.load(data)
    if root_path.present?
      data = self.lookup(root_path, data)
    end
    Array.wrap(data)
  end
end
