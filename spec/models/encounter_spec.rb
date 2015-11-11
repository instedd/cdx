require 'spec_helper'

describe Encounter do
  it { is_expected.to validate_presence_of :institution }

  let(:encounter) { Encounter.make }

  it "adds all test_results of sample" do
    sample_identifier = SampleIdentifier.make
    test1 = TestResult.make(sample_identifier: sample_identifier)
    test2 = TestResult.make(sample_identifier: sample_identifier)

    encounter.samples << sample_identifier.sample

    expect(encounter.test_results).to eq([test1, test2])
  end

  it "adds the sample of the test_result and the rest of the test_results" do
    sample_identifier = SampleIdentifier.make
    test1 = TestResult.make(sample_identifier: sample_identifier)
    test2 = TestResult.make(sample_identifier: sample_identifier)

    encounter.test_results << test1

    expect(encounter.samples).to eq([sample_identifier.sample])
    expect(encounter.test_results).to eq([test1, test2])
  end

  it "adds single test_result (without sample_identifier)" do
    test1 = TestResult.make(sample_identifier: nil)

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
    test1 = TestResult.make(sample_identifier: nil, patient: patient)

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
        {"condition" => "a", "result" => "positive"},
        {"condition" => "b", "result" => "positive"}]

      test1 = TestResult.make
      test1.core_fields[TestResult::ASSAYS_FIELD] = [
        {"condition" => "b", "result" => "negative"},
        {"condition" => "c", "result" => "negative"}]
      test1.save!

      encounter.add_test_result_uniq test1

      expect(encounter.core_fields[Encounter::ASSAYS_FIELD]).to eq([
        {"condition" => "a", "result" => "positive"},
        {"condition" => "b", "result" => "indeterminate"},
        {"condition" => "c", "result" => "negative"}
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

    it "merge by condition preserving value if equal" do
      expect(merge([{"condition" => "a", "result" => "positive"}], [{"condition" => "a", "result" => "positive"}]))
        .to eq([{"condition" => "a", "result" => "positive"}])
    end

    it "merge disjoint assays" do
      expect(merge([{"condition" => "a", "result" => "positive"}], [{"condition" => "b", "result" => "negative"}]))
        .to eq([{"condition" => "a", "result" => "positive"}, {"condition" => "b", "result" => "negative"}])
    end

    it "merge with conflicts produce indeterminate" do
      expect(merge([{"condition" => "a", "result" => "positive"}], [{"condition" => "a", "result" => "negative"}]))
        .to eq([{"condition" => "a", "result" => "indeterminate"}])
    end

    it "merge other properties priorizing first assay" do
      expect(merge([{"condition" => "a", "foo" => "foo", "other" => "first"}], [{"condition" => "a", "bar" => "bar", "other" => "second"}]))
        .to eq([{"condition" => "a", "foo" => "foo", "bar" => "bar", "other" => "first"}])
    end

    def merge_values(a, b)
      merge([{"condition" => "a", "result" => a}], [{"condition" => "a", "result" => b}]).first["result"]
    end

    it "merge n/a n/a" do
      expect(merge_values("n/a", "n/a")).to eq("indeterminate")
    end

    it "merge with same" do
      expect(merge_values("any", "any")).to eq("any")
    end

    it "merge with different" do
      expect(merge_values("any", "other")).to eq("indeterminate")
    end

    it "merge with n/a" do
      expect(merge_values("any", "n/a")).to eq("any")
      expect(merge_values("n/a", "any")).to eq("any")
    end

    it "merge with nil" do
      expect(merge_values("any", nil)).to eq("any")
      expect(merge_values(nil, "any")).to eq("any")
    end
  end

  context "field validations" do

    it "should allow observations pii field" do
      encounter.plain_sensitive_data[Encounter::OBSERVATIONS_FIELD] = "Observations"
      expect(encounter).to be_valid
    end

    it "should not allow observations plain field" do
      encounter.core_fields[Encounter::OBSERVATIONS_FIELD] = "Observations"
      expect(encounter).to_not be_valid
    end

    it "should allow assays fields" do
      encounter.core_fields[Encounter::ASSAYS_FIELD] = [{"name"=>"flu_a", "condition"=>"flu_a", "result"=>"indeterminate", "quantitative_result"=>3}]
      expect(encounter).to be_valid
    end

    it "should not allow invalid fields within assays" do
      encounter.core_fields[Encounter::ASSAYS_FIELD] = [{"name"=>"flu_a", "condition"=>"flu_a", "result"=>"indeterminate", "invalid"=>"invalid"}]
      expect(encounter).to_not be_valid
    end

  end

end
