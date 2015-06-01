class Hash
  def recursive_stringify_keys!
    stringify_keys!
    # stringify each hash in .values
    values.each{|h| h.recursive_stringify_keys! if h.is_a?(Hash) }
    # stringify each hash inside an array in .values
    values.select{|v| v.is_a?(Array) }.flatten.each{|h| h.recursive_stringify_keys! if h.is_a?(Hash) }
    self
  end

  def deep_merge_not_nil!(hash)
    self.deep_merge!(hash) { |key, v1, v2| v2.nil? ? v1 : v2 }
  end

  def reverse_deep_merge(other_hash)
    other_hash.deep_merge self
  end

  def reverse_deep_merge!(other_hash)
    replace(reverse_deep_merge(other_hash))
  end
end
