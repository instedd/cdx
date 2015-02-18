class Location < ActiveRecord::Base
  include Resource

  acts_as_nested_set dependent: :destroy

  has_many :laboratories, dependent: :restrict_with_error
  has_many :devices, :through => :laboratories
  has_many :events, :through => :laboratories
  validates_presence_of :parent, :geo_id
  validates_uniqueness_of :geo_id

  alias_attribute :admin_level, :depth

  def common_root_with(locations)
    locations.inject self do |location, root|
      if root.is_or_is_ancestor_of? location
        location
      elsif root.is_or_is_descendant_of? location
        root
      else
        root_ancestors = root.ancestors
        location.ancestors.sort_by{|l| l.depth}.reverse.find do |ancestor|
          root_ancestors.include? ancestor
        end
      end
    end
  end

  def self.create_from_geojson!(parent, feature)
    Location.create!(
      name: feature.name,
      geo_id: feature.location_id,
      lat: feature.center[1],
      lng: feature.center[0],
      parent: parent || find_or_create_default)
  end

  def self.update_from_geojson!(feature)
    location.update_attributes!(lat: feature.center[1], lng: feature.center[1])
  end

  def self.find_or_create_default
    find_by_depth(0) || create_default
  end

  def self.create_default
    location = self.new name: "World", geo_id: '0'
    location.save validate: false
    location
  end

end
