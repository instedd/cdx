require 'spec_helper'

describe Encounter do
  it { is_expected.to validate_presence_of :institution }

  let(:encounter) { Encounter.make }

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
