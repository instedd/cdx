require 'spec_helper'

describe Encounter do
  it { is_expected.to validate_presence_of :institution }

  let(:encounter) { Encounter.make }

  it "adds all test_results of sample" do
    sample = Sample.make
    test1 = TestResult.make(sample: sample)
    test2 = TestResult.make(sample: sample)

    encounter.samples << sample

    expect(encounter.test_results).to eq([test1, test2])
  end

  it "adds the sample of the test_result and the rest of the test_results" do
    sample = Sample.make
    test1 = TestResult.make(sample: sample)
    test2 = TestResult.make(sample: sample)

    encounter.test_results << test1

    expect(encounter.samples).to eq([sample])
    expect(encounter.test_results).to eq([test1, test2])
  end

  it "adds single test_result (without sample)" do
    test1 = TestResult.make(sample: nil)

    encounter.test_results << test1

    expect(encounter.samples).to eq([])
    expect(encounter.test_results).to eq([test1])
  end

  it "assigns patient from sample" do
    patient = Patient.make
    sample = Sample.make patient: patient

    encounter.samples << sample

    expect(encounter.patient).to eq(patient)
  end

  it "assigns patient from test_result" do
    patient = Patient.make
    test1 = TestResult.make(sample: nil, patient: patient)

    encounter.test_results << test1

    expect(encounter.patient).to eq(patient)
  end

  it "keeps patient if some sample does not have it" do
    patient = Patient.make
    sample1 = Sample.make patient: patient
    sample2 = Sample.make

    encounter.samples << sample1
    encounter.samples << sample2

    expect(encounter.patient).to eq(patient)
  end

  it "raises if multiple patient are set" do
    encounter.patient = Patient.make

    sample = Sample.make patient: Patient.make
    expect {
      encounter.samples << sample
    }.to raise_error(Encounter::MultiplePatientError)
  end

  it "raises if assigning sample of other encounter" do
    sample = Sample.make
    Encounter.make samples: [sample]

    expect {
      encounter.samples << sample
    }.to raise_error(Encounter::EncounterAlreadyAssignedError)
  end

  it "raises if assigning test_result of other encounter" do
    test1 = TestResult.make
    Encounter.make test_results: [test1]

    expect {
      encounter.test_results << test1
    }.to raise_error(Encounter::EncounterAlreadyAssignedError)
  end

  it "should not raise if already belongs to self" do
    test1 = TestResult.make
    encounter.test_results << test1
    encounter.test_results << test1
  end

  it "should add test_result without duplicated" do
    test1 = TestResult.make
    encounter.add_test_result_uniq test1
    encounter.add_test_result_uniq test1
    expect(encounter.test_results.count).to eq(1)
  end

  it "should add sample without duplicated" do
    sample = Sample.make
    encounter.add_sample_uniq sample
    encounter.add_sample_uniq sample
    expect(encounter.samples.count).to eq(1)
  end
end
