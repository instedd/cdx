module MapHelper
  def map_url(lat, lng, zoom=9, width=180, height=178)
    "http://maps.googleapis.com/maps/api/staticmap?center=#{lat},#{lng}&zoom=#{zoom}&size=#{width}x#{height}&style=feature:landscape|element:all|saturation:-100&style=feature:transit|element:all|saturation:-100&style=feature:landscape|element:all|saturation:-100&style=feature:poi|element:all|saturation:-100&style=feature:water|saturation:-100|invert_lightness:true&style=feature:road|element:all|saturation:-100&markers=color:red|#{lat},#{lng}#{"&key=#{google_maps_api_key}" if google_maps_api_key}"
  end

  private

  def google_maps_api_key
    ENV['GOOGLE_MAPS_API_KEY'] || Settings.google_maps_api_key
  end
end
