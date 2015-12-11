require 'spec_helper'

describe SampleIdentifier do
  context "blueprint" do
    let(:site) { Site.make }

    it "should use site institution for sample" do
      expect(SampleIdentifier.make(site: site).sample.institution).to eq(site.institution)
    end

    it "should be able to create without site for manufacturers" do
      expect(SampleIdentifier.make(sample: Sample.make(institution: Institution.make(:manufacturer))).site).to be_nil
    end

    it "should create from samples" do
      sample = Sample.make
      sample_ident = sample.sample_identifiers.make

      expect(sample.institution).to be_kind_institution
      expect(sample_ident.sample).to eq(sample)
      expect(sample_ident.site).to_not be_nil
      expect(sample_ident.site.institution).to eq(sample.institution)
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of :sample }

    context "validations for manufacturer" do
      let(:sample) { Sample.make institution: Institution.make(:manufacturer) }

      it "does not validate presence of site" do
        expect(SampleIdentifier.new(sample: sample, site: nil, entity_id: "100000")).to be_valid
      end
    end

    context "validations for institution" do
      let(:institution) { Institution.make(:institution) }
      let(:sample) { Sample.make institution: institution }
      let(:site) { Site.make institution: institution }

      it "validate presence of site" do
        expect(SampleIdentifier.new(sample: sample, site: site, entity_id: "100000")).to be_valid
        expect(SampleIdentifier.new(sample: sample, site: nil, entity_id: "100000")).to be_invalid
      end

      def expect_invalid_by_entity_id(sample_ident)
        expect(sample_ident).to be_invalid
        expect(sample_ident.errors[:entity_id]).to_not be_empty
      end

      it "should enforce uniqueness of entity_id per site" do
        SampleIdentifier.create!(sample: sample, site: site, entity_id: "100000")
        expect_invalid_by_entity_id SampleIdentifier.new(sample: sample, site: site, entity_id: "100000")
      end

      def it_recycle_within(start, before_next, start_next, start_next2)
        entity_id = "100000"

        Timecop.freeze(start)
        SampleIdentifier.create!(sample: sample, site: site, entity_id: entity_id)
        expect_invalid_by_entity_id SampleIdentifier.new(sample: sample, site: site, entity_id: entity_id)

        Timecop.freeze(before_next)
        expect_invalid_by_entity_id SampleIdentifier.new(sample: sample, site: site, entity_id: entity_id)

        Timecop.freeze(start_next)
        expect(SampleIdentifier.new(sample: sample, site: site, entity_id: entity_id)).to be_valid
        SampleIdentifier.create!(sample: sample, site: site, entity_id: entity_id)
        expect_invalid_by_entity_id SampleIdentifier.new(sample: sample, site: site, entity_id: entity_id)

        Timecop.freeze(start_next2)
        expect(SampleIdentifier.new(sample: sample, site: site, entity_id: entity_id)).to be_valid

        Timecop.return
      end

      it "works weekly" do
        site.sample_id_reset_policy = "weekly"
        site.save!
        it_recycle_within(
          Time.utc(2015, 12,  7, 15,  0, 0),
          Time.utc(2015, 12, 13, 23, 59, 0),
          Time.utc(2015, 12, 14,  0,  0, 0),
          Time.utc(2015, 12, 21,  0,  0, 0))
      end

      it "works monthly" do
        site.sample_id_reset_policy = "monthly"
        site.save!
        it_recycle_within(
          Time.utc(2015, 10,  3, 15,  0, 0),
          Time.utc(2015, 10, 30, 23, 59, 0),
          Time.utc(2015, 11,  1,  0,  0, 0),
          Time.utc(2015, 12,  1,  0,  0, 0))
      end

      it "works yearly" do
        site.sample_id_reset_policy = "yearly"
        site.save!
        it_recycle_within(
          Time.utc(2015, 10,  3, 15,  0, 0),
          Time.utc(2015, 12, 31, 23, 59, 0),
          Time.utc(2016,  1,  1,  0,  0, 0),
          Time.utc(2017,  2,  1,  0,  0, 0))
      end

      it "should be able to update" do
        sample_ident = SampleIdentifier.make sample: sample, site: site
        sample_ident.save!
      end
    end
  end
end
