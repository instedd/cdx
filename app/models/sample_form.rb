class SampleForm
  include ActiveModel::Model
  # shared editable attributes with model
  def self.shared_attributes
    [ :institution,
      :site,
      :uuid,
      :batch,
      :box,
      :date_produced,
      :lab_technician,
      :specimen_role,
      :isolate_name,
      :inactivation_method,
      :assay_attachments,
      :notes,
      :volume,
      :virus_lineage,
      :concentration_number,
      :replicate,
      :media,
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

  if Rails::VERSION::MAJOR >= 6
    include ActiveModel::Attributes
    attribute :date_produced, :date
  else
    def date_produced=(value)
      value = value.presence
      if value.is_a?(Time) || value.nil?
        @date_produced = value
      else
        @date_produced = value.to_time rescue nil
      end
    end
  end

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

    form_valid = self.valid?
    sample_valid = sample.valid?
    # copy validations from model to form to display errors if present
    sample.errors.each do |key, error|
      errors.add(key, error) if self.class.shared_attributes.include?(key) && !errors.include?(key)
    end
    return false unless form_valid && sample_valid

    sample.save
  end

  private

  def self.assign_attributes(target, source)
    shared_attributes.each do |attr|
      target.send("#{attr}=", source.send(attr))
    end
  end
end
