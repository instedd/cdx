class BatchForm
  include ActiveModel::Model

  # shared editable attributes with model
  def self.shared_attributes
    [ :institution,
      :isolate_name,
      :date_produced,
      :inactivation_method,
      :volume,
      :lab_technician ]
  end

  def self.model_name
    Batch.model_name
  end

  def model_name
    self.class.model_name
  end

  def self.human_attribute_name(*args)
    # required to bind validations to active record i18n
    Batch.human_attribute_name(*args)
  end

  attr_accessor *shared_attributes
  attr_accessor :samples_quantity
  delegate :id, :new_record?, :persisted?, to: :batch

  def batch
    @batch ||= Batch.new
  end

  def batch=(value)
    @batch = value
    self.class.assign_attributes(self, @batch)

    self.date_produced = if @batch.date_produced.is_a?(Time)
                           @batch.date_produced
                         else
                           Time.strptime(@batch.date_produced, date_format[:pattern]) rescue @batch.date_produced
                         end
  end

  def self.edit(batch)
    new.tap do |form|
      form.batch = batch
    end
  end

  def update(attributes)
    attributes.each do |attr, value|
      self.send("#{attr}=", value)
    end

    save
  end

  def save
    self.class.assign_attributes(batch, self)
    # we need to set a Time in batch instead of self.date_produced :: String
    batch.date_produced = @date_produced

    # validate forms. stop if invalid
    form_valid = self.valid?
    return false unless form_valid

    # validate/save. All done if succeeded
    is_valid = batch.save
    return true if is_valid

    # copy validations from model to form (form is valid, but model is not)
    batch.errors.each do |key, error|
      errors.add(key, error) if self.class.shared_attributes.include?(key)
    end
    return false
  end

  INACTIVATION_METHOD_VALUES = Batch.entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"

  validates_numericality_of :volume, :greater_than => 0, :less_than_or_equal_to => 100, :message => "Volume value must be between 0 and 100"
  validates_numericality_of :samples_quantity, :greater_than => 0, :message => "value must be greater than 0", on: :create

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

  private

  def self.assign_attributes(target, source)
    shared_attributes.each do |attr|
      target.send("#{attr}=", source.send(attr))
    end
  end
end
