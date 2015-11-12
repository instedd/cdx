class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include Resource

  ASSAYS_FIELD = 'assays'
  OBSERVATIONS_FIELD = 'observations'

  has_many :samples, dependent: :restrict_with_error
  has_many :test_results, dependent: :restrict_with_error

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  validate :validate_patient

  before_save :ensure_entity_id

  def entity_id
    core_fields["id"]
  end

  def has_entity_id?
    entity_id.not_nil?
  end

  def phantom?
    super && core_fields[ASSAYS_FIELD].blank? && plain_sensitive_data[OBSERVATIONS_FIELD].blank?
  end

  def self.merge_assays(assays1, assays2)
    return assays2 unless assays1
    return assays1 unless assays2

    assays1.dup.tap do |res|
      assays2.each do |assay2|
        assay = res.find { |a| a["condition"] == assay2["condition"] }
        if assay.nil?
          res << assay2.dup
        else
          assay.merge! assay2 do |key, v1, v2|
            if key == "result"
              values = []
              values << v1 if v1 && v1 != "n/a"
              values << v2 if v2 && v2 != "n/a"
              values << "indeterminate" if values.empty?
              values.uniq!
              if values.length == 1
                values.first
              else
                "indeterminate"
              end
            else
              v1
            end
          end
        end
      end
    end
  end

  def self.entity_scope
    "encounter"
  end

  def self.entity_fields
    super + additional_entity_fields
  end

  def self.additional_entity_fields
    @additional_entity_fields ||= Cdx::Scope.new('encounter', { allows_custom: true, fields: {
      observations: { pii: true },
      assays: {
        type: "nested",
        sub_fields: {
          name: {},
          condition: {},
          result: {},
          quantitative_result: { type: "integer" }
        }
      }
    }}.deep_stringify_keys).fields
  end

  def self.find_by_entity_id(entity_id, institution_id)
    find_by(entity_id: entity_id.to_s, institution_id: institution_id)
  end

  def self.query params, user
    EncounterQuery.for params, user
  end

  protected

  def ensure_entity_id
    self.entity_id = entity_id
  end
end
