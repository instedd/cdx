class Batch < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  has_many :laboratory_samples, dependent: :destroy, autosave: true

  def self.entity_scope
    "batch"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :batch_number, copy: true
  attribute_field :date_produced, :inactivation_method, :volume, :lab_technician

  INACTIVATION_METHOD_VALUES = Batch.entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_presence_of :inactivation_method
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"

  validates_presence_of :isolate_name
  validates_presence_of :date_produced
  validates_presence_of :volume
  validates_presence_of :lab_technician

  validate :date_produced_is_a_date

  validates :isolate_name, uniqueness: { scope: :batch_number }

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
end
