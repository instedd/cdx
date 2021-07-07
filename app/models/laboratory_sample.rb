class LaboratorySample < ActiveRecord::Base
  include Entity
  include AutoUUID

  belongs_to :institution
  validates_presence_of :institution

  belongs_to :batch

  has_one :test_qc_result
  has_many :notes

  accepts_nested_attributes_for :test_qc_result, allow_destroy: true
  accepts_nested_attributes_for :notes, allow_destroy: true

  def self.entity_scope
    "laboratory_sample"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :is_quality_control
  attribute_field :inactivation_method, :volume, :lab_technician, :production_date

  INACTIVATION_METHOD_VALUES = entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"

  validates_presence_of :isolate_name
  validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"
  validates_presence_of :lab_technician

  def build_default_test_qc_result
    build_test_qc_result
  end

  def new_notes=(notes_list = [])
    notes_list.each do |note|
      notes.build(
        description: note[:description],
        user: note[:user],
        )
    end
  end

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def production_date_placeholder
    date_format[:placeholder]
  end

end
