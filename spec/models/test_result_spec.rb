require 'spec_helper'

describe TestResult do
  it 'should validate same patient in sample' do
    test = TestResult.make
    test.should be_valid

    patient_a = Patient.make
    patient_b = Patient.make

    test.patient = patient_a
    test.sample.patient = patient_b

    test.should be_invalid
    test.should have(1).error_on(:patient_id)
  end
end
