module CustomMappingsHelper
  def options_for_target_field
    Device::CUSTOM_FIELD_TARGETS.inject([nil]) do |options, field|
      options << [field.to_s.titleize, field.to_s]
    end
  end
end
