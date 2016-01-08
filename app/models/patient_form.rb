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
    self.dob = Time.parse(@patient.dob) rescue nil # dob is stored as String, but in PatientForm it needs to be set as Time when editing
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
    patient.dob = @dob  # we need to set a Time in patient insead of self.dob :: String
    self.valid? && patient.save.tap do
      puts patient.errors.full_messages
    end
  end

  validates_presence_of :name
  GENDER_VALUES = Patient.entity_fields.detect { |f| f.name == 'gender' }.options
  validates_inclusion_of :gender, in: GENDER_VALUES, allow_blank: true, message: "is not within valid options (should be one of #{GENDER_VALUES.join(', ')})"

  # begin dob
  # @dob is Time | Nil | String.
  # PatientForm#dob will return always a string ready to be used by the user input with the user locale
  # PatientForm#dob= will accept either String or Time. The String will be converted if possible to a Time using the user locale
  validate :dob_is_a_date

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def dob
    value = @dob

    if value.is_a?(Time)
      return value.strftime(date_format[:pattern])
    end

    value
  end

  def dob=(value)
    value = nil if value.blank?

    @dob = if value.is_a?(String)
      Time.strptime(value, date_format[:pattern]) rescue value
    else
      value
    end
  end

  def dob_placeholder
    date_format[:placeholder]
  end

  def dob_is_a_date
    return if @dob.blank?
    errors.add(:dob, "should be a date in #{dob_placeholder}") unless @dob.is_a?(Time)
  end
  # end dob

  private

  def self.assign_attributes(target, source)
    shared_attributes.each do |attr|
      target.send("#{attr}=", source.send(attr))
    end
  end
end
