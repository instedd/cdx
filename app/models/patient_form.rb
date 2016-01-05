class PatientForm
  include ActiveModel::Model

  def self.model_name
    Patient.model_name
  end

  def model_name
    self.class.model_name
  end

  def self.human_attribute_name(*args)
    # required to bind validations to active record i18n
    Patient.human_attribute_name(*args)
  end

  attr_accessor :institution, :name, :dob, :lat, :lng, :location_geoid, :address, :email, :phone

  def attributes
    [:institution, :name, :dob, :lat, :lng, :location_geoid, :address, :email, :phone].inject({}) do |hash, key|
      hash[key] = self.send(key.to_s)
      hash
    end
  end

  def to_patient
    Patient.new(attributes)
  end

  def save
    valid? && to_patient.save
  end

  validates_presence_of :name

  # begin dob
  # use dob_text from form. dob is parsed dob_text or just dob_text if not a valid date
  # since the store is @dob, dob_text acts as a wrapper when the value is a date and formats it
  # for form rendering
  validate :dob_is_a_date

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def dob_text
    self.dob.try { |v| v.is_a?(Time) ? v.strftime(date_format[:pattern]) : v }
  end

  def dob_text=(value)
    self.dob = if value.is_a?(String)
       Time.strptime(value, date_format[:pattern]) rescue value
    else
      value
    end
  end

  def dob_text_placeholder
    date_format[:placeholder]
  end

  def dob_is_a_date
    errors.add(:dob_text, "should be a date in #{dob_text_placeholder}") unless dob.is_a?(Time)
  end
  # end dob

end
