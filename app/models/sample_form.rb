class SampleForm
  include ActiveModel::Model
  # shared editable attributes with model
  def self.shared_attributes
    [ :institution,
      :site,
      :uuid,
      :batch,
      :date_produced,
      :lab_technician,
      :specimen_role,
      :isolate_name,
      :inactivation_method,
      :assay_attachments,
      :notes,
      :volume,
      :qc_info ]
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
  delegate :uuid, :assay_attachments, :notes, :qc_info, to: :sample

  validates_presence_of :date_produced

  def self.for(sample)
    new.tap do |form|
      form.sample = sample
    end
  end

  def sample
    @sample
  end

  def sample=(value)
    @sample = value
    self.class.assign_attributes(self, @sample)

    self.date_produced =
      if @sample.date_produced.is_a?(Time)
        @sample.date_produced
      else
        Time.strptime(@sample.date_produced, Sample.date_format[:pattern]) rescue @sample.date_produced
      end
  end

  def batch_number
    batch.try(&:batch_number) || sample.old_batch_number
  end

  # Used by fields_for
  def assay_attachments_attributes=(assays)
    @sample.assay_attachments_attributes = assays
  end

  # Used by fields_for
  def notes_attributes=(notes)
    @sample.notes_attributes = notes
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

    form_valid = self.valid?
    sample_valid = sample.valid?
    # copy validations from patient to form (form is valid, but patient is not)
    sample.errors.each do |key, error|
      errors.add(key, error) if self.class.shared_attributes.include?(key) && !errors.include?(key)
    end
    return false unless form_valid && sample_valid 

    # validate/save. All done if succeeded
    is_valid = sample.save
    return true if is_valid

    return false
  end


  # begin date_produced
  # @date_produced is Time | Nil | String.
  # BatchForm#date_produced will return always a string ready to be used by the user input with the user locale
  # BatchForm#date_produced= will accept either String or Time. The String will be converted if possible to a Time using the user locale
  # validate :date_produced_is_a_date
  #
  def date_produced
    value = @date_produced

    if value.is_a?(Time)
      return value.strftime(Sample.date_format[:pattern])
    end

    value
  end

  def date_produced=(value)
    value = nil if value.blank?

    @date_produced = if value.is_a?(String)
      Time.strptime(value, Sample.date_format[:pattern]) rescue value
    else
      value
    end
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
