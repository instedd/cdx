class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include Resource

  ASSAYS_FIELD = 'assays'
  OBSERVATIONS_FIELD = 'observations'

  has_many :samples, before_add: [:check_no_encounter, :assign_patient, :add_test_results]
  has_many :test_results, before_add: [:check_no_encounter, :assign_patient, :add_sample]

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  # TODO assign the encounter's patient to all test_result and sample.

  class MultiplePatientError < StandardError
  end

  class EncounterAlreadyAssignedError < StandardError
  end

  def entity_id
    core_fields["id"]
  end

  def self.entity_scope
    "encounter"
  end

  def add_sample_uniq(sample)
    self.samples << sample unless self.samples.include?(sample)
  end

  def add_test_result_uniq(test_result)
    self.test_results << test_result unless self.test_results.include?(test_result)

    self.core_fields[Encounter::ASSAYS_FIELD] = Encounter.merge_assays(
      self.core_fields[Encounter::ASSAYS_FIELD],
      test_result.core_fields[TestResult::ASSAYS_FIELD])
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

  private

  def add_test_results(sample)
    @skip_add_sample = true
    sample.test_results.each do |test_result|
      self.add_test_result_uniq test_result
    end
    @skip_add_sample = false
  end

  def add_sample(test_result)
    return if @skip_add_sample
    self.add_sample_uniq test_result.sample if test_result.sample
  end

  def check_no_encounter(sample_or_test_result)
    return if sample_or_test_result.encounter.nil?
    if sample_or_test_result.encounter_id != self.id
      raise EncounterAlreadyAssignedError, "Unable to add #{sample_or_test_result.model_name.human.downcase} that already belongs to other encounter"
    end
  end

  def assign_patient(sample_or_test_result)
    new_patient = sample_or_test_result.patient
    return unless new_patient

    if self.patient.nil?
      self.patient = new_patient
    elsif self.patient != new_patient
      raise MultiplePatientError, "Unable to add #{sample_or_test_result.model_name.human.downcase} of multiple patients"
    end
  end

  def self.find_by_entity_id(entity_id, institution_id)
    find_by(entity_id: entity_id.to_s, institution_id: institution_id)
  end
end
