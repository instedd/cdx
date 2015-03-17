Location; class Location

  def self.create_from_geojson!(parent, feature)
    parent ||= Location.find_or_create_default
    Location.create!(attributes_from_feature(feature).merge({
      geo_id: feature.location_id,
      parent: parent,
      admin_level: parent.admin_level + 1}))
  end

  def update_from_geojson!(feature)
    update_attributes!(self.class.attributes_from_feature(feature))
  end

  private

  def self.attributes_from_feature(feature)
    {
      name: feature.name,
      lat: feature.center[1],
      lng: feature.center[0],
    }
  end

end
