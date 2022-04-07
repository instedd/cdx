class Location
  module WithCache
    @cache = nil

    def with_cache
      @cache = Hash.new { |hash, key| hash[key] = {} }
      yield
    ensure
      @cache = nil
    end

    def find(geo_id, options = {})
      if geo_id.blank?
        nil
      elsif @cache
        @cache[options][geo_id] ||= super
      else
        super
      end
    end
  end

  class << self
    prepend WithCache

    def common_root(locations)
      locations.map(&:self_and_ancestors).inject(:&).last
    end
  end

  alias_method :geo_id, :id
  alias_method :admin_level, :level

  def parent
    ancestors.last
  end

  def self_and_ancestors
    ancestors + [self]
  end
end
