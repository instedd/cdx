class PatientForm
  include ActiveModel::Model

  def self.shared_attributes # shared editable attributes with patient model
    [:institution, :name, :gender, :dob, :lat, :lng, :location_geoid, :address, :email, :phone]
  end

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

  attr_accessor *shared_attributes
  delegate :id, :new_record?, :persisted?, to: :patient

  def patient
    @patient ||= Patient.new
  end

  def patient=(value)
    @patient = value
    self.class.assign_attributes(self, @patient)
  end

  def self.edit(patient)
    new.tap do |form|
      form.patient = patient
    end
  end

  def update(attributes)
    attributes.each do |attr, value|
      self.send("#{attr}=", value)
    end

    save
  end

  def save
    self.class.assign_attributes(patient, self)
    self.valid? && patient.save
  end

  validates_presence_of :name
  GENDER_VALUES = Patient.entity_fields.detect { |f| f.name == 'gender' }.options
  validates_inclusion_of :gender, in: GENDER_VALUES, allow_blank: true, message: "is not within valid options (should be one of #{GENDER_VALUES.join(', ')})"

  # begin dob
  # use dob_text from form. dob is parsed dob_text or just dob_text if not a valid date
  # since the store is @dob, dob_text acts as a wrapper when the value is a date and formats it
  # for form rendering
  validate :dob_is_a_date

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def dob_text
    value = self.dob
    value = Time.parse(value) rescue value if value.is_a?(String) # dob attribute seems to be stored as YYYY-MM-DD string instead of a Time

    if value.is_a?(Time)
      return value.strftime(date_format[:pattern])
    end

    value
  end

  def dob_text=(value)
    value = nil if value.blank?

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
    return if dob.blank?
    errors.add(:dob_text, "should be a date in #{dob_text_placeholder}") unless dob.is_a?(Time)
  end
  # end dob

  private

  def self.assign_attributes(target, source)
    shared_attributes.each do |attr|
      target.send("#{attr}=", source.send(attr))
    end
  end
end
