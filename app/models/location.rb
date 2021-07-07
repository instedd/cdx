class Location

  alias_method :geo_id, :id
  alias_method :admin_level, :level

  def parent
    ancestors.last
  end

  def self_and_ancestors
    ancestors + [self]
  end

  class << self
    @cache = nil

    def common_root(locations)
      locations.map(&:self_and_ancestors).inject(:&).last
    end

    def find_with_cache(geoid, opts={})
      return nil if geoid.blank?
      return find_without_cache(geoid, opts) if @cache.nil?
      (@cache[opts] ||= {})[geoid] ||= find_without_cache(geoid, opts)
    end

    def with_cache
      @cache = Hash.new
      yield
      @cache = nil
    end

    # alias_method_chain :find, :cache
    alias_method :find_without_cache, :find
    alias_method :find, :find_with_cache
  end

end
