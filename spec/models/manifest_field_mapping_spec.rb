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

    describe "multiple values" do

      it "clusterises an empty list" do
        mapping.clusterise([], [5, 20, 40]).should eq([])
      end

      it "clusterises a list with a single value" do
        mapping.clusterise([7], [5, 20, 40]).should eq(["5-20"])
      end

      it "clusterises a list with multiple values" do
        mapping.clusterise([8, 6, 56], [5, 20, 40]).should eq(["5-20", "5-20", "40+"])
      end

      it "clusterises a list with duplicated values" do
        mapping.clusterise([8, 6, 56, 8], [5, 20, 40]).should eq(["5-20", "5-20", "40+", "5-20"])
      end

      it "clusterises a list with nil values" do
        mapping.clusterise([8, 6, nil, 56, 8], [5, 20, 40]).should eq(["5-20", "5-20", nil, "40+", "5-20"])
      end

    end
  end

end
