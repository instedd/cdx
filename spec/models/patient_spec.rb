require 'spec_helper'

describe Patient do

  context "validations" do

    it "should make a valid patient" do
      expect(Patient.make_unsaved).to be_valid
      expect(Patient.make_unsaved :phantom).to be_valid
    end

    it "should make phantom if required" do
      expect(Patient.make :phantom).to be_phantom
    end

    it "should make non phantom if required" do
      expect(Patient.make).to_not be_phantom
    end

    it "should validate uniqness of entity_id_hash and entity_id" do
      institution = Institution.make
      Patient.make entity_id: '1001', institution: institution
      patient = Patient.make_unsaved entity_id: '1001', institution: institution

      expect(patient).to be_invalid
      expect(patient.errors).to have_key(:entity_id_hash)
      expect(patient.errors).to have_key(:entity_id)
    end

    context "on fields" do
      let(:patient) { Patient.make_unsaved }

      it "should support valid core fields" do
        patient.core_fields['gender'] = 'male'
        expect(patient).to be_valid
      end

      it "should support valid sensitive fields" do
        patient.plain_sensitive_data['name'] = 'John Doe'
        expect(patient).to be_valid
      end

      it "should validate invalid core fields" do
        patient.core_fields['gender'] = 'invalid'
        expect(patient).to be_invalid
      end

      it "should validate non existing core fields" do
        patient.core_fields['inexistent'] = 'value'
        expect(patient).to be_invalid
      end

      it "should validate non existing sensitive fields" do
        patient.plain_sensitive_data['inexistent'] = 'value'
        expect(patient).to be_invalid
      end

      it "should validate pii fields in core fields" do
        patient.core_fields['name'] = 'John Doe'
        expect(patient).to be_invalid
      end

      it "should validate non-pii fields in sensitive fields" do
        patient.plain_sensitive_data['gender'] = 'male'
        expect(patient).to be_invalid
      end

    end

  end

end
