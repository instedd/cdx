class Hash

  def deep_merge_not_nil!(hash)
    self.deep_merge!(hash) { |key, v1, v2| v2.nil? ? v1 : v2 }
  end

  def reverse_deep_merge!(other_hash)
    replace(other_hash.deep_merge(self))
  end

  def get_in(*path)
    step = path.shift
    value = self[step]
    return value if path.empty?
    return nil if value.nil?
    return value.get_in(*path)
  end

end
