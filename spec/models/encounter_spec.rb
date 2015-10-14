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

  describe "add_test_result_uniq" do
    it "should add without duplicated" do
      test1 = TestResult.make
      encounter.add_test_result_uniq test1
      encounter.add_test_result_uniq test1
      expect(encounter.test_results.count).to eq(1)
    end

    it "should merge encounter assays" do
      encounter.core_fields[Encounter::ASSAYS_FIELD] = [
        {name: "a", result: :positive},
        {name: "b", result: :positive}]

      test1 = TestResult.make
      test1.core_fields[TestResult::ASSAYS_FIELD] = [
        {name: "b", result: :negative},
        {name: "c", result: :negative}]
      test1.save!

      encounter.add_test_result_uniq test1

      expect(encounter.core_fields[Encounter::ASSAYS_FIELD]).to eq([
        {name: "a", result: :positive},
        {name: "b", result: :indeterminate},
        {name: "c", result: :negative}
      ])
    end
  end

  it "should add sample without duplicated" do
    sample = Sample.make
    encounter.add_sample_uniq sample
    encounter.add_sample_uniq sample
    expect(encounter.samples.count).to eq(1)
  end

  describe "merge assays" do
    def merge(a, b)
      Encounter.merge_assays(a, b)
    end

    it "merge nils" do
      expect(merge(nil, nil)).to be_nil
    end

    it "merge nil with empty" do
      expect(merge(nil, [])).to eq([])
      expect(merge([], nil)).to eq([])
    end

    it "merge by name preserving value if equal" do
      expect(merge([{name: "a", result: :positive}], [{name: "a", result: :positive}]))
        .to eq([{name: "a", result: :positive}])
    end

    it "merge disjoint assays" do
      expect(merge([{name: "a", result: :positive}], [{name: "b", result: :negative}]))
        .to eq([{name: "a", result: :positive}, {name: "b", result: :negative}])
    end

    it "merge with conflicts produce indeterminate" do
      expect(merge([{name: "a", result: :positive}], [{name: "a", result: :negative}]))
        .to eq([{name: "a", result: :indeterminate}])
    end

    it "merge other properties priorizing first assay" do
      expect(merge([{name: "a", foo: 'foo', other: 'first'}], [{name: "a", bar: 'bar', other: 'second'}]))
        .to eq([{name: "a", foo: 'foo', bar: 'bar', other: 'first'}])
    end

  end
end
