module SitesHelper

  def site_address_component(site)
    react_component 'Address',
      latName: 'site[lat]', lngName: 'site[lng]', addressName: 'site[address]', locationName: 'site[location]',
      defaultLocation: site.location_geoid,
      defaultAddress: site.address,
      defaultLatLng: { lat: site.lat, lng: site.lng }
  end

end
