class Batch < ActiveRecord::Base
  include Entity
  include AutoUUID
  include Resource
  include SpecimenRole
  include SiteContained

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

  DATE_FORMAT = { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }

  INACTIVATION_METHOD_VALUES = Batch.entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_presence_of :inactivation_method
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"

  validates_presence_of :date_produced
  validates_presence_of :volume
  validates_presence_of :lab_technician
  validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"

  validate :date_produced_is_a_date

  validate :isolate_name_batch_number_combination_create, on: :create
  validate :isolate_name_batch_number_combination_update, on: :update

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

  def isolate_name_batch_number_combination_create
    validate_isolate_name_batch_number_combination {
      [ "#{query} AND id IS NOT NULL" ] + query_params
    }
  end

  def isolate_name_batch_number_combination_update
    validate_isolate_name_batch_number_combination {
      [ "#{query} AND id != ?" ] + query_params + [ id ]
    }
  end

  def query
    "LOWER(isolate_name) = ? AND LOWER(batch_number) = ?"
  end

  def query_params
    [ isolate_name.downcase, batch_number.downcase ]
  end

  def validate_isolate_name_batch_number_combination
    return unless (present?(:isolate_name) && present?(:batch_number))

    combination_exists = Batch.where(yield).exists?
    if combination_exists
      errors.add(:isolate_name, "and Batch Number combination should be unique")
    end
  end

  def present?(attr_name)
    valid = self[attr_name].present?
    errors.add(attr_name, "can't be blank") unless valid
    valid
  end
end
