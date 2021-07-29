class SampleForm
  include ActiveModel::Model

  # shared editable attributes with model
  def self.shared_attributes
    [ :institution,
      :uuid,
      :date_produced,
      :lab_technician,
      :specimen_role,
      :isolate_name,
      :inactivation_method,
      :volume ]
  end

  def self.model_name
    Sample.model_name
  end

  def model_name
    self.class.model_name
  end

  def self.human_attribute_name(*args)
    # required to bind validations to active record i18n
    Sample.human_attribute_name(*args)
  end

  attr_accessor *shared_attributes
  delegate :id, :new_record?, :persisted?, to: :sample
  delegate :uuid, :assay_attachments, :notes, to: :sample

  def self.for(sample)
    new.tap do |form|
      form.sample = sample
    end
  end

  def sample
    @sample # ||= Sample.new
  end

  def sample=(value)
    @sample = value
    self.class.assign_attributes(self, @sample)

    self.date_produced =
      if @sample.date_produced.is_a?(Time)
        @sample.date_produced
      else
        Time.strptime(@sample.date_produced, date_format[:pattern]) rescue @sample.date_produced
      end
  end

  # Used by fields_for
  def assay_attachments_attributes=(assays)
    @sample.assay_attachments_attributes = assays
  end

  # Used by fields_for
  def notes_attributes=(notes)
    @sample.notes_attributes = notes
  end

  def new_assays=(assays = [])
    @sample.new_assays = assays
  end

  def new_notes=(notes = [])
    @sample.new_notes = notes
  end

  def self.edit(sample)
    new.tap do |form|
      form.sample = sample
    end
  end

  def update(attributes)
    attributes.each do |attr, value|
      self.send("#{attr}=", value)
    end

    save
  end

  def save
    self.class.assign_attributes(sample, self)
    # we need to set a Time in sample instead of self.date_produced :: String
    sample.date_produced = @date_produced

    # validate forms. stop if invalid
    form_valid = self.valid?
    return false unless form_valid

    # validate/save. All done if succeeded
    is_valid = sample.save
    return true if is_valid

    # copy validations from model to form (form is valid, but model is not)
    sample.errors.each do |key, error|
      errors.add(key, error) if self.class.shared_attributes.include?(key)
    end
    return false
  end

  validates_presence_of :lab_technician
  SPECIMEN_ROLE_VALUES = Sample.entity_fields.detect { |f| f.name == 'specimen_role' }.options
  validates_inclusion_of :specimen_role, in: SPECIMEN_ROLE_VALUES, message: "is not within valid options (should be one of #{SPECIMEN_ROLE_VALUES.join(', ')})"
  validates_presence_of :isolate_name
  INACTIVATION_METHOD_VALUES = Sample.entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"
  validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"

  # begin date_produced
  # @date_produced is Time | Nil | String.
  # BatchForm#date_produced will return always a string ready to be used by the user input with the user locale
  # BatchForm#date_produced= will accept either String or Time. The String will be converted if possible to a Time using the user locale
  validate :date_produced_is_a_date

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def date_produced
    value = @date_produced

    if value.is_a?(Time)
      return value.strftime(date_format[:pattern])
    end

    value
  end

  def date_produced=(value)
    value = nil if value.blank?

    @date_produced = if value.is_a?(String)
      Time.strptime(value, date_format[:pattern]) rescue value
    else
      value
    end
  end

  def date_produced_placeholder
    date_format[:placeholder]
  end

  def date_produced_is_a_date
    return if @date_produced.blank?
    errors.add(:date_produced, "should be a date in #{date_produced_placeholder}") unless @date_produced.is_a?(Time)
  end
  # end date_produced
  #

  private

  def self.assign_attributes(target, source)
    shared_attributes.each do |attr|
      target.send("#{attr}=", source.send(attr))
    end
  end
end
