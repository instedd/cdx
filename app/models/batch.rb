class Batch < ActiveRecord::Base
  include Entity
  include AutoUUID
  include Resource

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

  SPECIMEN_ROLES = YAML.load_file(File.join(File.dirname(__FILE__), ".", "config", "specimen_roles.yml"))["specimen_roles"]
  DATE_FORMAT = { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }

  INACTIVATION_METHOD_VALUES = Batch.entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_presence_of :inactivation_method
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"

  validates_presence_of :date_produced
  validates_presence_of :volume
  validates_presence_of :lab_technician
  validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"

  validate :date_produced_is_a_date

  validate :isolate_name_batch_number_combination

  def date_produced_description
    if date_produced.is_a?(Time)
      return date_produced.strftime(I18n.t('date.input_format.pattern'))
    end

    date_produced
  end

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def date_produced_placeholder
    self.date_format[:placeholder]
  end

  private

  def date_produced_is_a_date
    return if date_produced.blank?
    errors.add(:date_produced, "should be a date in #{date_produced_placeholder}") unless date_produced.is_a?(Time)
  end

  def isolate_name_batch_number_combination
    if isolate_name.blank? or batch_number.blank?
      errors.add(:isolate_name, "can't be blank") if isolate_name.blank?
      errors.add(:batch_number, "can't be blank") if batch_number.blank?
      return
    end

    combination_query = [
      "LOWER(isolate_name) = ? AND LOWER(batch_number) = ? AND id != ?",
      isolate_name.downcase, batch_number.downcase, self.id
    ]

    if Batch.where(combination_query).exists?
      errors.add(:isolate_name, "and Batch Number combination should be unique")
    end
  end
end
