require 'spec_helper'

describe TestResult do
  it 'should validate same patient in sample' do
    test = TestResult.make
    expect(test).to be_valid

    patient_a = Patient.make
    patient_b = Patient.make

    test.patient = patient_a
    test.sample.patient = patient_b

    expect(test).to be_invalid
    expect(test.errors[:patient_id].size).to eq(1)
  end

  it "gets test result in the past year" do
    test1 = TestResult.make created_at: 2.years.ago
    test2 = TestResult.make created_at: 11.months.ago

    tests = TestResult.within_time(1.year, Time.now).all
    expect(tests).to eq([test2])
  end

  it "sets the site_prefix" do
    test = TestResult.make
    expect(test.site_prefix).to eq(test.device.site.prefix)
  end
end
