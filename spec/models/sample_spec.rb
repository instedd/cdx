require 'spec_helper'

describe Sample do

  context "merge" do

    let(:sample) do
      Sample.make.tap do |s|
        s.sample_identifiers.make(entity_id: 'id:a', uuid: 'uuid:A')
        s.sample_identifiers.make(entity_id: 'id:b', uuid: 'uuid:B')
      end
    end

    it "should join identifiers from both samples" do
      other_sample = Sample.make_unsaved(sample_identifiers: [
        SampleIdentifier.new(entity_id: 'id:c', uuid: 'uuid:C'),
        SampleIdentifier.new(entity_id: 'id:d', uuid: 'uuid:D')
      ])

      sample.merge(other_sample)

      expect(sample.sample_identifiers.map(&:entity_id)).to contain_exactly('id:a','id:b','id:c','id:d')
      expect(sample.sample_identifiers.map(&:uuid)).to contain_exactly('uuid:A','uuid:B','uuid:C','uuid:D')
    end

    it "should add repeated identifiers with an uuid" do
      other_sample = Sample.make_unsaved(sample_identifiers: [
        SampleIdentifier.new(entity_id: 'id:a', uuid: 'uuid:X'),
        SampleIdentifier.new(entity_id: 'id:d', uuid: 'uuid:D')
      ])

      sample.merge(other_sample)

      expect(sample.sample_identifiers.map(&:entity_id)).to contain_exactly('id:a','id:b','id:d','id:a')
      expect(sample.sample_identifiers.map(&:uuid)).to contain_exactly('uuid:A','uuid:B','uuid:D','uuid:X')
    end

  end

end
