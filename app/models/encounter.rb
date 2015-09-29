class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash

  has_many :samples, before_add: [:assign_patient, :add_test_results]
  has_many :test_results, before_add: [:assign_patient, :add_sample]

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  class MultiplePatientError < StandardError
  end

  def entity_id
    core_fields["id"]
  end

  def self.entity_scope
    "encounter"
  end

  private

  def add_test_results(sample)
    @skip_add_sample = true
    self.test_results << sample.test_results
    @skip_add_sample = false
  end

  def add_sample(test_result)
    return if @skip_add_sample
    self.samples << test_result.sample if test_result.sample
  end

  def assign_patient(sample_or_test_result)
    new_patient = sample_or_test_result.patient
    return unless new_patient

    if self.patient.nil?
      self.patient = new_patient
    elsif self.patient != new_patient
      raise MultiplePatientError, "Unable to add samples and tests_results of multiple patients"
    end
  end
end
