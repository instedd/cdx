class Batch < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  has_many :samples, dependent: :destroy, autosave: true

  def self.entity_scope
    "batch"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :batch_number, copy: true
  attribute_field :date_produced,
                  :lab_technician,
                  :specimen_role,
                  :inactivation_method,
                  :volume

  SPECIMEN_ROLES = YAML.load(File.read("#{Rails.root.to_s}/app/models/static_data/specimen_roles.yml"))["specimen_roles"]

  INACTIVATION_METHOD_VALUES = Batch.entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_presence_of :inactivation_method
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"

  validates_presence_of :date_produced

  validate :date_produced_is_a_date

  validate :isolate_name_batch_number_combination

  def date_produced_description
    if date_produced.is_a?(Time)
      return date_produced.strftime(I18n.t('date.input_format.pattern'))
    end

    date_produced
  end

  private

  def date_produced_is_a_date
    errors.add(:date_produced, "should be a date") unless date_produced.is_a?(Time)
  end

  def isolate_name_batch_number_combination
    combination_query = [
      "LOWER(isolate_name) = ? AND LOWER(batch_number) = ? AND id != ?",
      isolate_name.downcase, batch_number.downcase, self.id
    ]

    if Batch.where(combination_query).exists?
      errors.add(:isolate_name, "and Batch Number combination should be unique")
    end
  end
end
