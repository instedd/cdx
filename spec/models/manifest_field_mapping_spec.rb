require 'spec_helper'

describe ManifestFieldMapping do

  describe "clusterisation" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil) }

    describe "single values" do

      it "clusterises values lower than lower bound" do
        mapping.clusterise(1, [5, 20, 40]).should eq("0-5")
      end

      pending "clusterises doesn't assume 0 as lower bound" do
        mapping.clusterise(1, [5, 20, 40]).should eq("<5")
      end

      pending "clusterises negative values" do
        mapping.clusterise(-1, [5, 20, 40]).should eq("<5")
      end

      it "clusterises values lower than lower bound" do
        mapping.clusterise(-1, [-5, 5, 20, 40]).should eq("-5-5")
      end

      pending "clusterises values lower than lower bound" do
        mapping.clusterise(-10, [-5, 5, 20, 40]).should eq("<-5")
      end

      it "clusterises values greater than upper bound" do
        mapping.clusterise(42, [5, 20, 40]).should eq("40+")
      end

      it "clusterises nil" do
        mapping.clusterise(nil, [5, 20, 40]).should eq(nil)
      end

    end
  end

end
