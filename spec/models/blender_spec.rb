require 'spec_helper'

describe Blender do

  # Setup of all these entities is quite expensive, so they are set up at the beginning of this fixture,
  # modified within a transaction and rolled back in each test and reloaded,
  # then deleted via truncation on the end of the fixture
  before(:all) do
    DatabaseCleaner.clean_with :truncation
    LocationService.fake!

    @institution = Institution.make

    @patient_p1 = @institution.patients.make(is_phantom: false)
    @patient_p2 = @institution.patients.make(is_phantom: false)

    @encounter_p1e1 = @patient_p1.encounters.make(is_phantom: false)
    @encounter_p1e2 = @patient_p1.encounters.make(is_phantom: false)
    @encounter_p1e3 = @patient_p1.encounters.make(is_phantom: false)
    @encounter_p2e1 = @patient_p2.encounters.make(is_phantom: false)

    @sample_p1e1s1 = @encounter_p1e1.samples.make(is_phantom: false)
    @sample_p1e1s2 = @encounter_p1e1.samples.make(is_phantom: false)
    @sample_p1e2s1 = @encounter_p1e2.samples.make(is_phantom: false)
    @sample_p2e1s1 = @encounter_p2e1.samples.make(is_phantom: false)

    @test_p1e1s1t1 = TestResult.make_from_sample(@sample_p1e1s1)
    @test_p1e1s1t2 = TestResult.make_from_sample(@sample_p1e1s1)
    @test_p1e1s2t1 = TestResult.make_from_sample(@sample_p1e1s2)
    @test_p1e2s1t1 = TestResult.make_from_sample(@sample_p1e2s1)
    @test_p1e3s0t1 = TestResult.make_from_encounter(@encounter_p1e3)
    @test_p1e0s0t1 = TestResult.make_from_patient(@patient_p1)
    @test_p2e1s1t1 = TestResult.make_from_sample(@sample_p2e1s1)

    @other_institution = Institution.make
    @other_patient = @other_institution.patients.make(is_phantom: false)
    @other_encounter = @other_patient.encounters.make(is_phantom: false)
    @other_sample = @other_encounter.samples.make(is_phantom: false)
    @other_test = TestResult.make_from_sample(@other_sample)
  end

  after(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  before(:each) do
    [@institution,
    @patient_p1,
    @patient_p2,
    @encounter_p1e1,
    @encounter_p1e2,
    @encounter_p1e3,
    @encounter_p2e1,
    @sample_p1e1s1,
    @sample_p1e1s2,
    @sample_p1e2s1,
    @sample_p2e1s1,
    @test_p1e1s1t1,
    @test_p1e1s1t2,
    @test_p1e1s2t1,
    @test_p1e2s1t1,
    @test_p1e3s0t1,
    @test_p1e0s0t1,
    @test_p2e1s1t1,
    @other_institution,
    @other_patient,
    @other_encounter,
    @other_sample,
    @other_test].each(&:reload)
  end

  let(:blender) { Blender.new(@institution) }


  shared_examples "loads all entities" do

    it "should load patient" do
      expect(blender.patients.map(&:single_entity)).to contain_exactly(@patient_p1)
    end

    it "should load encounters" do
      expect(blender.encounters.map(&:single_entity)).to contain_exactly(@encounter_p1e1, @encounter_p1e2, @encounter_p1e3)
    end

    it "should load samples" do
      expect(blender.samples.map(&:single_entity)).to contain_exactly(@sample_p1e1s1, @sample_p1e1s2, @sample_p1e2s1)
    end

    it "should load tests" do
      expect(blender.test_results.map(&:single_entity)).to contain_exactly(@test_p1e1s1t1, @test_p1e1s1t2, @test_p1e1s2t1, @test_p1e3s0t1, @test_p1e0s0t1, @test_p1e2s1t1)
    end

  end


  shared_examples "has valid invariant" do

    let(:blenders) { blender.blenders.values.flatten }

    it "having all entities from the same institution" do
      blenders.each do |b|
        expect(b.institution).to eq(blender.institution)
        expect(b.entities.map(&:institution).uniq).to contain_exactly(blender.institution)
      end
    end

    it "storing blenders in the correct collection" do
      expect(blender.patients.map(&:class).uniq).to contain_exactly(Blender::PatientBlender)
      expect(blender.encounters.map(&:class).uniq).to contain_exactly(Blender::EncounterBlender)
      expect(blender.samples.map(&:class).uniq).to contain_exactly(Blender::SampleBlender)
      expect(blender.test_results.map(&:class).uniq).to contain_exactly(Blender::TestResultBlender)
    end

    it "having each blender registerd as child of each parent" do
      blenders.flatten.each do |b|
        b.parents.values.each do |parent|
          expect(parent.children).to include(b)
          expect(blenders).to include(parent)
        end
      end
    end

    it "having each blender registerd as parent of each child" do
      blenders.each do |b|
        b.children.each do |child|
          expect(child.parents[b.entity_type]).to eq(b)
          expect(blenders).to include(child)
        end
      end
    end

    it "having each blender with the same ancestors as its parents" do
      blenders.each do |b|
        b.parents.each do |_, parent|
          parent.parents.each do |kind, ancestor|
            expect(b.parents[kind]).to eq(ancestor)
          end
        end
      end
    end

  end

  context "setup" do
    it "should have created two institutions" do
      expect(Institution.all).to contain_exactly(@institution, @other_institution)
    end

    it "should have created three patients" do
      expect(Patient.all).to contain_exactly(@patient_p1, @patient_p2, @other_patient)
    end

    it "should have created five encounters" do
      expect(Encounter.all).to contain_exactly(@encounter_p1e1, @encounter_p1e2, @encounter_p1e3, @encounter_p2e1, @other_encounter)
    end

    it "should have created five samples" do
      expect(Sample.all).to contain_exactly(@sample_p1e1s1, @sample_p1e1s2, @sample_p2e1s1, @sample_p1e2s1, @other_sample)
    end

    it "should have created eight tests" do
      expect(TestResult.all).to contain_exactly(@test_p1e1s1t1, @test_p1e1s1t2, @test_p1e1s2t1, @test_p1e3s0t1, @test_p2e1s1t1, @test_p1e0s0t1, @test_p1e2s1t1, @other_test)
    end
  end

  context "loading a test" do
    before(:each) { blender.load(@test_p1e1s1t1) }
    include_examples "loads all entities"
    include_examples "has valid invariant"
  end

  context "loading a sample" do
    before(:each) { blender.load(@sample_p1e1s1) }
    include_examples "loads all entities"
    include_examples "has valid invariant"
  end

  context "loading an encounter" do
    before(:each) { blender.load(@encounter_p1e1) }
    include_examples "loads all entities"
    include_examples "has valid invariant"
  end

  context "loading a patient" do
    before(:each) { blender.load(@patient_p1) }
    include_examples "loads all entities"
    include_examples "has valid invariant"
  end


  context "returning existing data" do
    before(:each) { blender.load(@patient_p1) }
    let!(:blender_p1e1) { blender.load(@encounter_p1e1) }

    include_examples "loads all entities"
    include_examples "has valid invariant"

    it "should return encounter" do
      expect(blender_p1e1.single_entity).to eq(@encounter_p1e1)
    end
  end


  context "changing a sample to another encounter" do

    let(:blender_p1e1s2)   { blender.load(@sample_p1e1s2)  }
    let(:blender_p1e2)     { blender.load(@encounter_p1e2) }
    let(:blender_p1e1s2t1) { blender.load(@test_p1e1s2t1)  }

    before(:each) do
      blender.set_parent(blender_p1e1s2, blender_p1e2)
    end

    include_examples "has valid invariant"

    it "should reassign its encounter" do
      expect(blender_p1e1s2.encounter).to eq(blender_p1e2)
    end

    it "should reassign the encounter of its tests" do
      expect(blender_p1e1s2t1.encounter).to eq(blender_p1e2)
    end

    it "should save changes" do
      blender.save_without_index!
      expect(@sample_p1e1s2.reload.encounter).to eq(@encounter_p1e2)
      expect(@test_p1e1s2t1.reload.encounter).to eq(@encounter_p1e2)
    end

  end


  context "changing a sample to another encounter from a different patient" do

    let(:blender_p2)       { blender.load(@patient_p2)     }
    let(:blender_p2e1)     { blender.load(@encounter_p2e1) }
    let(:blender_p1e1s2)   { blender.load(@sample_p1e1s2)  }
    let(:blender_p1e1s2t1) { blender.load(@test_p1e1s2t1)  }

    let(:blender_p1e1s1)   { blender.load(@sample_p1e1s1)  }
    let(:blender_p1e1)     { blender.load(@encounter_p1e1) }

    before(:each) do
      blender.set_parent(blender_p1e1s2, blender_p2e1)
    end

    include_examples "has valid invariant"

    it "should reassign its encounter" do
      expect(blender_p1e1s2.encounter).to eq(blender_p2e1)
    end

    it "should reassign the encounter of its tests" do
      expect(blender_p1e1s2t1.encounter).to eq(blender_p2e1)
    end

    it "should reassign its patient" do
      expect(blender_p1e1s2.patient).to eq(blender_p2)
    end

    it "should reassign the patient of its tests" do
      expect(blender_p1e1s2t1.patient).to eq(blender_p2)
    end

    it "should not modify the patient of other samples" do
      expect(blender_p1e1s1.encounter).to eq(blender_p1e1)
    end

    it "should save changes" do
      blender.save_without_index!

      expect(@sample_p1e1s2.reload.encounter).to eq(@encounter_p2e1)
      expect(@sample_p1e1s2.reload.patient).to eq(@patient_p2)

      expect(@test_p1e1s2t1.reload.encounter).to eq(@encounter_p2e1)
      expect(@test_p1e1s2t1.reload.patient).to eq(@patient_p2)
    end

  end


  context "merging a test result encounter" do

    let(:blender_p1e2s1t1) { blender.load(@test_p1e2s1t1) }
    let(:blender_p1e2s1) { blender.load(@sample_p1e2s1) }
    let(:blender_p1e2) { blender.load(@encounter_p1e2) }
    let(:blender_p1e1) { blender.load(@encounter_p1e1) }

    context "when phantom" do

      before(:each) do
        @encounter_p1e2.update_attributes!(is_phantom: true, core_fields: Hash.new)
        blender.merge_parent(blender_p1e2s1t1, blender_p1e1)
      end

      it "should merge both encounters" do
        expect(blender_p1e1.entities).to contain_exactly(@encounter_p1e1, @encounter_p1e2)
      end

      it "should reassign test encounter" do
        expect(blender_p1e2s1t1.encounter).to eq(blender_p1e1)
      end

      it "should reassign sample encounter" do
        expect(blender_p1e2s1.encounter).to eq(blender_p1e1)
      end

      it "should save changes" do
        blender.save_without_index!

        expect(@encounter_p1e2.reload.test_results.to_a).to be_empty
        expect(@encounter_p1e2.reload.samples.to_a).to be_empty

        expect(@test_p1e2s1t1.reload.encounter).to eq(@encounter_p1e1)
        expect(@sample_p1e2s1.reload.encounter).to eq(@encounter_p1e1)
      end

    end

    context "when non phantom" do

      it "should not be able to merge encounters" do
        expect {
          blender.merge_parent(blender_p1e2s1t1, blender_p1e1)
        }.to raise_error(Blender::MergeNonPhantomError)
      end

    end

  end


  context "merging a test result encounter from another patient" do

    before(:each) do
      @encounter_p2e1.update_attributes!(is_phantom: true, core_fields: Hash.new)
    end

    let(:blender_p1) { blender.load(@patient_p1) }
    let(:blender_p2) { blender.load(@patient_p2) }

    let(:blender_p1e1) { blender.load(@encounter_p1e1) }
    let(:blender_p2e1) { blender.load(@encounter_p2e1) }

    let(:blender_p2e1s1)   { blender.load(@sample_p2e1s1) }
    let(:blender_p2e1s1t1) { blender.load(@test_p2e1s1t1) }

    let(:blender_p1e1s1)   { blender.load(@sample_p1e1s1) }
    let(:blender_p1e1s1t1) { blender.load(@test_p1e1s1t1) }

    context "when phantom" do

      before(:each) do
        @patient_p2.attributes = { is_phantom: true, plain_sensitive_data: Hash.new, entity_id_hash: nil }
        @patient_p2.save(validate: false)
        blender.merge_parent(blender_p2e1s1t1, blender_p1e1)
      end

      it "should merge both patients" do
        expect(blender_p1.entities).to contain_exactly(@patient_p1, @patient_p2)
      end

      it "should reassign the patient for the test" do
        expect(blender_p2e1s1t1.patient).to eq(blender_p1)
      end

      it "should reassign the patient for the sample" do
        expect(blender_p2e1s1.patient).to eq(blender_p1)
      end

      it "should save changes" do
        blender.save_without_index!

        expect(@patient_p2.reload.test_results.to_a).to be_empty
        expect(@patient_p2.reload.samples.to_a).to be_empty
        expect(@encounter_p2e1.reload.test_results.to_a).to be_empty
        expect(@encounter_p2e1.reload.samples.to_a).to be_empty

        expect(@test_p2e1s1t1.reload.patient).to eq(@patient_p1)
        expect(@sample_p2e1s1.reload.patient).to eq(@patient_p1)
      end

    end

    context "when merging on phantom" do

      before(:each) do
        @patient_p2.attributes = { is_phantom: true, plain_sensitive_data: Hash.new, entity_id_hash: nil }
        @patient_p2.save(validate: false)
        blender.merge_parent(blender_p1e1s1t1, blender_p2e1)
      end

      it "should merge both encounters" do
        expect(blender_p2e1.entities).to contain_exactly(@encounter_p1e1, @encounter_p2e1)
      end

      it "should merge both patients" do
        expect(blender_p2.entities).to contain_exactly(@patient_p1, @patient_p2)
      end

      it "should reassign the encounter for the test" do
        expect(blender_p1e1s1t1.encounter).to eq(blender_p2e1)
      end

      it "should reassign the patient for the test" do
        expect(blender_p1e1s1t1.patient).to eq(blender_p2)
      end

      it "should reassign the encounter for the sample" do
        expect(blender_p1e1s1.encounter).to eq(blender_p2e1)
      end

      it "should reassign the patient for the sample" do
        expect(blender_p1e1s1.patient).to eq(blender_p2)
      end

      it "should save changes" do
        blender.save_without_index!

        expect(@patient_p2.reload.test_results.to_a).to be_empty
        expect(@patient_p2.reload.samples.to_a).to be_empty
        expect(@encounter_p2e1.reload.test_results.to_a).to be_empty
        expect(@encounter_p2e1.reload.samples.to_a).to be_empty

        expect(@test_p1e1s1t1.reload.patient).to  eq(@patient_p1)
        expect(@test_p1e1s1t2.reload.patient).to  eq(@patient_p1)
        expect(@test_p1e1s2t1.reload.patient).to  eq(@patient_p1)
        expect(@sample_p1e1s1.reload.patient).to  eq(@patient_p1)
        expect(@sample_p1e1s2.reload.patient).to  eq(@patient_p1)
        expect(@encounter_p1e1.reload.patient).to eq(@patient_p1)

        expect(@test_p1e1s1t1.reload.encounter).to  eq(@encounter_p1e1)
        expect(@test_p1e1s1t2.reload.encounter).to  eq(@encounter_p1e1)
        expect(@test_p1e1s2t1.reload.encounter).to  eq(@encounter_p1e1)
        expect(@sample_p1e1s1.reload.encounter).to  eq(@encounter_p1e1)
        expect(@sample_p1e1s2.reload.encounter).to  eq(@encounter_p1e1)

        expect(@test_p2e1s1t1.reload.patient).to eq(@patient_p1)
        expect(@sample_p2e1s1.reload.patient).to eq(@patient_p1)

        expect(@test_p2e1s1t1.reload.encounter).to eq(@encounter_p1e1)
        expect(@sample_p2e1s1.reload.encounter).to eq(@encounter_p1e1)
      end

    end

    context "when non phantom" do

      it "should not be able to merge patients" do
        expect {
          blender.merge_parent(blender_p2e1s1t1, blender_p1e1)
        }.to raise_error(Blender::MergeNonPhantomError)
      end

    end

  end

end
