module PatientsHelper

  def patient_address_component(patient)
    react_component 'Address',
      latName: 'patient[lat]', lngName: 'patient[lng]', addressName: 'patient[address]', locationName: 'patient[location_geoid]',
      defaultLocation: patient.location_geoid,
      defaultAddress: patient.address,
      defaultLatLng: { lat: patient.lat, lng: patient.lng }
  end

end
