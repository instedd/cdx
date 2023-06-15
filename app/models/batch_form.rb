class BatchForm
  include ActiveModel::Model

  # shared editable attributes with model
  def self.shared_attributes
    [ :institution,
      :site,
      :batch_number,
      :date_produced,
      :lab_technician,
      :specimen_role,
      :isolate_name,
      :inactivation_method,
      :volume,
      :virus_lineage,
      :reference_gene,
      :target_organism_taxonomy_id,
      :pango_lineage,
      :who_label]
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

  validates_presence_of :date_produced
  validates_numericality_of :samples_quantity, greater_than_or_equal_to: 0, message: "value must be greater or equal to 0", if: :creating_batch?

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

  def self.for(batch)
    new.tap do |form|
      form.batch = batch
    end
  end

  def batch
    @batch
  end

  def batch=(value)
    @batch = value
    self.class.assign_attributes(self, @batch)
  end

  def create
    batch.samples = self.samples_quantity.times.map { build_sample }
    save
  end

  def add_sample
    batch.samples.push build_sample
    save
  end

  def build_sample
    batch.build_sample(
      date_produced: @date_produced,
      volume: volume,
    )
  end

  def update(attributes, remove_sample_ids)
    attributes.each do |attr, value|
      self.send("#{attr}=", value)
    end

    @batch.samples.each do |sample|
      sample.mark_for_destruction if remove_sample_ids.include? sample.id
    end

    save
  end

  def save
    self.class.assign_attributes(batch, self)
    form_valid = self.valid?
    batch_valid = batch.valid?
    # copy validations from model to form to display errors if present
    batch.errors.each do |key, error|
      errors.add(key, error) if self.class.shared_attributes.include?(key) && !errors.include?(key)
    end
    return false unless form_valid && batch_valid

    # validate/save. All done if succeeded
    batch.save
    save_autocomplete_values
  end

  def creating_batch?
    self.batch.id.nil?
  end

  private

  def save_autocomplete_values
    institution = batch.institution
    ["reference_gene", "target_organism_taxonomy_id", "pango_lineage", "who_label"].each do |field_name|
      autocomplete_value = institution.autocomplete_values.find_or_initialize_by(
        field_name: field_name,
        value: batch.send(field_name)
      )
      autocomplete_value.save
    end
  end

  def self.assign_attributes(target, source)
    shared_attributes.each do |attr|
      target.send("#{attr}=", source.send(attr))
    end
  end
end
