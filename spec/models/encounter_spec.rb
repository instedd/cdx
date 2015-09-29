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
end
