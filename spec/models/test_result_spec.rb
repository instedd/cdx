require 'spec_helper'

describe TestResult do
  it 'should validate same patient in sample' do
    test = TestResult.make!
    expect(test).to be_valid

    patient_a = Patient.make!
    patient_b = Patient.make!

    test.patient = patient_a
    test.sample.patient = patient_b

    expect(test).to be_invalid
    expect(test.errors[:patient_id].size).to eq(1)
  end

  it "gets test result in the past year" do
    test1 = TestResult.make! created_at: 2.years.ago
    test2 = TestResult.make! created_at: 11.months.ago

    tests = TestResult.within_time(1.year, Time.now).all
    expect(tests).to eq([test2])
  end

  it "sets the site_prefix" do
    site = Site.make!
    device = Device.make!(site: site)
    test = TestResult.make!(device: device)
    expect(test.site_prefix).to eq(test.device.site.prefix)
  end

  context "field validations" do
    let(:test) { TestResult.make }

    it "should support valid core fields" do
      test.core_fields['name'] = 'test name'
      expect(test).to be_valid
    end

    it "should support nested assays" do
      test.core_fields['assays'] = [
        { 'name' => 'assay/flu', 'condition' => 'flu', 'result' => 'positive' },
        { 'name' => 'assay/mtb', 'condition' => 'mtb', 'result' => 'negative' }
      ]
      expect(test).to be_valid
    end

    it "should validate nested assays for inexistent fields" do
      test.core_fields['assays'] = [
        { 'name' => 'assay/flu', 'condition' => 'flu', 'result' => 'positive', 'inexistent' => 'value' },
        { 'name' => 'assay/mtb', 'condition' => 'mtb', 'result' => 'negative' }
      ]
      expect(test).to be_invalid
    end

    it "should validate nested assays for invalid fields" do
      test.core_fields['assays'] = [
        { 'name' => 'assay/flu', 'condition' => 'flu', 'result' => 'positive' },
        { 'name' => 'assay/mtb', 'condition' => 'mtb', 'result' => 'invalid-value' }
      ]
      expect(test).to be_invalid
    end
  end
end
