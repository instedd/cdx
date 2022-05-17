require 'spec_helper'

describe Sample do

  context "merge" do
    let!(:institution) { Institution.make }
    let!(:site) { Site.make institution: institution }

    let(:sample) do
      Sample.make(institution: institution, sample_identifiers: [
        SampleIdentifier.new(entity_id: 'id:a', uuid: 'uuid:A'),
        SampleIdentifier.new(entity_id: 'id:b', uuid: 'uuid:B')
      ])
    end

    it "should join identifiers from both samples" do
      other_sample = Sample.make(institution: institution, sample_identifiers: [
        SampleIdentifier.new(site: site, entity_id: 'id:c', uuid: 'uuid:C'),
        SampleIdentifier.new(site: site, entity_id: 'id:d', uuid: 'uuid:D')
      ])

      sample.merge(other_sample)

      expect(sample.sample_identifiers.map(&:entity_id)).to contain_exactly('id:a','id:b','id:c','id:d')
      expect(sample.sample_identifiers.map(&:uuid)).to contain_exactly('uuid:A','uuid:B','uuid:C','uuid:D')
    end

    it "should add repeated identifiers with an uuid" do
      other_site = Site.make(institution: institution)
      other_sample = Sample.make(sample_identifiers: [
        SampleIdentifier.new(site: other_site, entity_id: 'id:a', uuid: 'uuid:X'),
        SampleIdentifier.new(site: other_site, entity_id: 'id:d', uuid: 'uuid:D')
      ])

      sample.merge(other_sample)

      expect(sample.sample_identifiers.map(&:entity_id)).to contain_exactly('id:a','id:b','id:d','id:a')
      expect(sample.sample_identifiers.map(&:uuid)).to contain_exactly('uuid:A','uuid:B','uuid:D','uuid:X')
    end

  end

  it "has_qc_reference?" do
    expect(Sample.make.has_qc_reference?).to eq(false)
    expect(Sample.make(qc_info: QcInfo.make).has_qc_reference?).to eq(true)

    Batch.make(samples: [
      Sample.make(specimen_role: "q"),
      sample = Sample.make(specimen_role: "p"),
    ])
    expect(sample.has_qc_reference?).to eq(true)
  end

  it "#detach_from_context" do
    sample = Sample.make(:batch)
    batch = sample.batch
    sample.detach_from_context
    expect(sample.site).to be_nil
    expect(sample.institution).to be_nil
    expect(sample.batch).to be_nil
    expect(sample.old_batch_number).to eq batch.batch_number
  end
end
