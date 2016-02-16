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

  context "within" do
    let!(:site) { Site.make }
    let!(:subsite) { Site.make parent: site, institution: site.institution }
    let!(:other_site) { Site.make }
    let!(:patient1) { Patient.make site: site, institution: site.institution }
    let!(:patient2) { Patient.make site: subsite, institution: site.institution }
    let!(:patient3) { Patient.make site: other_site, institution: other_site.institution }
    let!(:patient4) { Patient.make site: nil, institution: site.institution }

    it "institution, no exclusion, should show patients from site, subsites and no site" do
      expect(Patient.within(site.institution).to_a).to eq([patient1, patient2, patient4])
    end

    it "institution, with exclusion, should show patients with no site" do
      expect(Patient.within(site.institution,true).to_a).to eq([patient4])
    end

    it "site, no exclusion, should show patients from site and subsite" do
      expect(Patient.within(site).to_a).to eq([patient1, patient2])
    end

    it "site, with exclusion, should show patients from site only" do
      expect(Patient.within(site,true).to_a).to eq([patient1])
    end

    it "institution should not show patients from other institutions" do
      expect(Patient.within(other_site.institution).to_a).to eq([patient3])
    end
  end
end
