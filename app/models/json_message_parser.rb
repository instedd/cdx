class JsonMessageParser

  PATH_ROOT_TOKEN = "$"

  def lookup(path, data, root = data)
    paths = path.split Manifest::PATH_SPLIT_TOKEN
    paths.inject data do |current, path|
      next root if path == PATH_ROOT_TOKEN

      # This check is for nested fields
      if current.is_a?(Array)
        current.map do |sub|
          if sub.is_a?(Hash)
            sub[path]
          end
        end
      else
        if current.is_a? Hash
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
