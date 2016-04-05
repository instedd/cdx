module EntityIndexableFields

  def test_fields(test_result)
    return Hash.new if test_result.nil?

    test_result.core_fields.merge({
      "reported_time" => test_result.created_at.utc.iso8601,
      "updated_time" => test_result.updated_at.utc.iso8601,
      "uuid" => test_result.uuid
    }).merge('custom_fields' => test_result.custom_fields)
  end

  def sample_fields(sample)
    return Hash.new if sample.nil?

    fields = sample.core_fields.merge('custom_fields' => sample.custom_fields)
    %W(uuid entity_id).each do |identifier|
      values = sample.sample_identifiers.map(&identifier.to_sym).compact
      fields[identifier] = values unless values.blank?
    end
    fields
  end

  def encounter_fields(encounter)
    return Hash.new if encounter.nil?
    if encounter.user_id != nil
      user_email = encounter.user.email
    else
      user_email = nil
    end
    encounter.core_fields.merge('custom_fields' => encounter.custom_fields).merge('uuid' => encounter.uuid, 'user_email' => user_email)
  end

  def patient_fields(patient)
    return Hash.new if patient.nil?
    patient.core_fields.merge('custom_fields' => patient.custom_fields).merge('uuid' => patient.uuid)
  end

  def device_fields(device)
    return Hash.new if device.nil?
    return {
      "uuid" => device.uuid,
      "model" => device.device_model.name,
      "serial_number" => device.serial_number
    }
  end

  def location_fields(location)
    return Hash.new if location.nil?
    parent_locations = location.try(:self_and_ancestors) || []

    return {
      "id" => location.try(:geo_id),
      "parents" => parent_locations.map(&:geo_id),
      "admin_levels" => Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }],
      "lat" => location.try(:lat),
      "lng" => location.try(:lng)
    }
  end

  def institution_fields(institution)
    return Hash.new if institution.nil?
    { 'uuid' => institution.uuid }
  end

  def site_fields(site)
    return Hash.new if site.nil?
    { 'uuid' => site.uuid, 'path' => site.path }
  end


end
