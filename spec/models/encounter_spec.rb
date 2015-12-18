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

  context "update diagnostic" do
    let(:device) { Device.make site: encounter.site }

    before(:each) { Timecop.freeze(Time.now) }
    after(:each) { Timecop.return }
    it "by default shold not be marked as dirty" do
      expect(encounter).to_not have_dirty_diagnostic
    end

    def add_sample_and_process_later(sample_entity_id, message)
      encounter.samples.make sample_identifiers: [SampleIdentifier.make_unsaved(site: encounter.site, entity_id: sample_entity_id)]

      Timecop.freeze(Time.now + 1.second)

      DeviceMessage.create_and_process device: device, plain_text_data: Oj.dump(message.merge(sample: {id: sample_entity_id}))
    end

    def saved_diagnostic
      encounter.core_fields[Encounter::ASSAYS_FIELD]
    end

    context "when processing new message from a sample in the encounter" do
      let(:sample_entity_id) { "1001" }
      let(:message) { { test: { assays: [
        {condition: "flu_a", name: "flu_a", result: "positive"}
      ] } } }

      before(:each) {
        add_sample_and_process_later(sample_entity_id, message)
        encounter.reload
      }

      it "should not update de diagnostic" do
        expect(saved_diagnostic).to be_nil
      end

      it "should have sample and test_results" do
        expect(encounter.samples.count).to eq(1)
        expect(encounter.test_results.count).to eq(1)
      end

      it "should be marked as dirty" do
        expect(encounter).to have_dirty_diagnostic
      end

      it "should suggest new diagnosis" do
        expect(encounter.updated_diagnostic).to eq([{"condition" => "flu_a", "name" => "flu_a", "result" => "positive", "quantitative_result" => nil}])
      end
    end

    context "when processing new message from a sample in the encounter with existing diagnostic" do
      let(:sample_entity_id) { "1001" }
      let(:message) { { test: { assays: [
        {condition: "flu_a", name: "flu_a", result: "positive"},
        {condition: "flu_b", name: "flu_b", result: "positive"},
        {condition: "mtb", name: "mtb", result: "negative"},
      ] } } }

      before(:each) {
        add_sample_and_process_later("999", { test: { assays: [
          {condition: "flu_a", name: "flu_a", result: "negative"},
        ] } })

        Timecop.freeze(Time.now + 1.second)

        encounter.core_fields[Encounter::ASSAYS_FIELD] = [
          {"condition" => "flu_a", "name" => "flu_a", "result" => "positive", "quantitative_result" => nil},
          {"condition" => "flu_c", "name" => "flu_c", "result" => "negative", "quantitative_result" => nil},
          {"condition" => "mtb", "name" => "mtb", "result" => "positive", "quantitative_result" => 32},
        ]
        encounter.save!
        encounter.updated_diagnostic_timestamp!

        add_sample_and_process_later(sample_entity_id, message)
        encounter.reload
      }

      it "should only have messaged after timestamp as pending" do
        expect(encounter.test_results_not_in_diagnostic).to eq([TestResult.last])
      end

      it "should be marked as dirty" do
        expect(encounter).to have_dirty_diagnostic
      end

      it "should suggest new diagnosis" do
        expect(encounter.updated_diagnostic).to eq([
          {"condition" => "flu_a", "name" => "flu_a", "result" => "positive", "quantitative_result" => nil},
          {"condition" => "flu_c", "name" => "flu_c", "result" => "negative", "quantitative_result" => nil},
          {"condition" => "mtb", "name" => "mtb", "result" => "indeterminate", "quantitative_result" => 32},
          {"condition" => "flu_b", "name" => "flu_b", "result" => "positive", "quantitative_result" => nil},
        ])
      end

      it "should remove dirty after updated_diagnostic_timestamp" do
        encounter.updated_diagnostic_timestamp!
        expect(encounter).to_not have_dirty_diagnostic
      end
    end
  end

end
