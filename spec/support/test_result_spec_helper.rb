# Ensure TestResult class is loaded first from app/models before reopening it to ensure its super class is properly set
TestResult; class TestResult
  def self.create_and_index params={}
    test = self.make params
    TestResultIndexer.new(test).index(true)
    test
  end

  def self.make_from_entity(institution, args={})
    defaults = ({
      institution: institution,
      device_messages: [],
      device: Device.make(institution: institution, site: nil)
    })

    TestResult.make(defaults.merge(args))
  end

  def self.make_from_sample(sample, args={})
    make_from_entity(sample.institution, {
      sample_identifier: SampleIdentifier.make(sample: sample),
      encounter: sample.encounter,
      patient: sample.patient
    }.merge(args))
  end

  def self.make_from_encounter(encounter, args={})
    make_from_entity(encounter.institution, {
      sample_identifier: nil,
      encounter: encounter,
      patient: encounter.patient
    }.merge(args))
  end

  def self.make_from_patient(patient, args={})
    make_from_entity(patient.institution, {
      sample_identifier: nil,
      encounter: nil,
      patient: patient
    }.merge(args))
  end
end
