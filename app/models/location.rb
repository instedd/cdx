class Location

  include Resource

  alias_method :geo_id, :id
  alias_method :admin_level, :level

  def parent
    ancestors.last
  end

  def self_and_ancestors
    ancestors + [self]
  end

  def self.common_root(locations)
    locations.map(&:self_and_ancestors).inject(:&).last
  end

end
