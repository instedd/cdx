class LocationsInitializer
  def initialize(location_tree)
    @location_tree = location_tree
  end

  def create_location(location_attributes, parent=Location.find_or_create_default)
    geo_id = location_attributes[:geo_id]
    location = Location.find_by_geo_id(geo_id)
    if location.nil?
      location = Location.create!(name: location_attributes[:name],
                                 parent: parent,
                                 lat: location_attributes[:lat],
                                 lng: location_attributes[:lng],
                                 admin_level: parent.admin_level + 1,
                                 geo_id: geo_id)
    elsif location.lat.nil? || location.lng.nil?
      location.update_attributes lat: location_attributes[:lat], lng: location_attributes[:lng], geo_id: location_attributes[:geo_id]
    end

    location_attributes[:children].each do |child_attributes|
      create_location(child_attributes, location)
    end if location_attributes[:children]
  end

  def run
    @location_tree.each do |attrs|
      create_location(attrs)
    end
  end
end
