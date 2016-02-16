module WithLocation
  extend ActiveSupport::Concern

  included do
    def location(opts={})
      return nil if self.location_geoid.blank?
      @location = nil if @location_opts.presence != opts.presence || @location.try(:geo_id) != location_geoid
      @location_opts = opts
      @location ||= Location.find(location_geoid, opts)
    end

    def location=(value)
      @location = value
      self.location_geoid = value.try(:id)
    end

    def self.preload_locations!
      locations = Location.details(all.map(&:location_geoid).map(&:presence).compact.uniq).index_by(&:id)
      all.to_a.each do |record|
        record.location = locations[record.location_geoid]
      end
    end
  end
end
