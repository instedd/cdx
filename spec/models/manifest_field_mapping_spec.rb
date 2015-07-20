require 'spec_helper'

describe ManifestFieldMapping do
  describe "clusterisation" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil, nil) }

    describe "single values" do
      it "clusterises values lower than lower bound" do
        mapping.clusterise(1, [5, 20, 40]).should eq("<5")
      end

      it "clusterises negative values" do
        mapping.clusterise(-1, [5, 20, 40]).should eq("<5")
      end

      it "clusterises values lower than lower bound" do
        mapping.clusterise(-1, [-5, 5, 20, 40]).should eq("-5-5")
      end

      it "clusterises values lower than lower bound" do
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

  describe "strip" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil, nil) }

    describe "single values" do
      it "stripes an empty string" do
        mapping.strip("").should eq("")
      end

      it "stripes a blank string" do
        mapping.strip(" ").should eq("")
      end

      it "stripes a blank string" do
        mapping.strip("       ").should eq("")
      end

      it "stripes newlines" do
        mapping.strip("\n").should eq("")
      end

      it "stripes nil" do
        mapping.strip(nil).should eq(nil)
      end

      it "stripes an stripped string" do
        mapping.strip("hi there").should eq("hi there")
      end

      it "stripes a non-empty string" do
        mapping.strip(" hi there        ").should eq("hi there")
      end

      it "stripes newlines from non-empty strings" do
        mapping.strip("\n\n hi there \n   \n").should eq("hi there")
      end
    end

    describe "multiple values" do
      it "strips an empty list" do
        mapping.strip([]).should eq([])
      end

      it "strips a list with a single value" do
        mapping.strip([" hi there "]).should eq(["hi there"])
      end

      it "strips a list with multiple values" do
        mapping.strip([" hi there ", "hi", "", "\n\nhi "]).should eq(["hi there", "hi", "", "hi"])
      end

      it "strips a list with duplicated values" do
        mapping.strip([" hi there ", "hi", "", "\n\nhi ", "hi", " hi there "]).should eq(["hi there", "hi", "", "hi", "hi", "hi there"])
      end

      it "strips a list with nil values" do
        mapping.strip([" hi there ", "hi", nil, "", "\n\nhi ", "hi", " hi there "]).should eq(["hi there", "hi", nil, "", "hi", "hi", "hi there"])
      end
    end
  end

  describe "lowercase" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil, nil) }

    describe "single values" do
      it "downcase an empty string" do
        mapping.lowercase("").should eq("")
      end

      it "downcase a lowercase string" do
        mapping.lowercase("foo").should eq("foo")
      end

      it "downcase nil" do
        mapping.lowercase(nil).should eq(nil)
      end

      it "downcase an uppercase string" do
        mapping.lowercase("FOO").should eq("foo")
      end

      it "downcase an uppercase string" do
        mapping.lowercase("Foo").should eq("foo")
      end

      it "downcase an uppercase string" do
        mapping.lowercase("Foo Bar Baz").should eq("foo bar baz")
      end
    end

    describe "multiple values" do
      it "downcase an empty list" do
        mapping.lowercase([]).should eq([])
      end

      it "downcase a list with a single value" do
        mapping.lowercase(["HI ThERe "]).should eq(["hi there "])
      end

      it "downcase a list with multiple values" do
        mapping.lowercase(["Hi There", "hi", "", "\n\nHI "]).should eq(["hi there", "hi", "", "\n\nhi "])
      end

      it "downcase a list with duplicated values" do
        mapping.lowercase(["Hi There", "hi", "","Hi There", "Hi"]).should eq(["hi there", "hi", "", "hi there", "hi"])
      end

      it "downcase a list with nil values" do
        mapping.lowercase(["Hi There", "hi", nil,"Hi There", "Hi"]).should eq(["hi there", "hi", nil, "hi there", "hi"])
      end
    end
  end

  describe "collect" do
    let(:manifest) {
      manifest = double()
      manifest.stub(:parser) { JsonMessageParser.new }
      manifest
    }

    context "without using root object" do
      let(:mapping) {
        ManifestFieldMapping.new(manifest, nil, nil, nil)
      }

      describe "works as identity for single values" do
        it "collects single values" do
          mapping.collect({ "id" => "flu-a","name" => "Flu A" }, {"lookup" => "name"}).should eq("Flu A")
        end

        it "collects nil values" do
          mapping.collect(nil, {"lookup" => "name"}).should eq(nil)
        end
      end

      describe "multiple values" do
        it "collects an empty list" do
          mapping.collect([], {"lookup" => "name"}).should eq([])
        end

        it "collects a list with a single value" do
          mapping.collect([ { "id" => "flu-a","name" => "Flu A" } ], {"lookup" => "name"}).should eq(["Flu A"])
        end

        it "collects a list with multiple values" do
          mapping.collect(
            [
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-b","name" => "Flu B" }
            ],
            {"lookup" => "name"}
          ).should eq(["Flu A", "Flu B"])
        end

        it "collects a list with duplicated values" do
          mapping.collect(
            [
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-b","name" => "Flu B" }
            ],
            {"lookup" => "name"}
          ).should eq(["Flu A", "Flu A", "Flu B"])
        end

        it "clusterises a list with nil values" do
          mapping.collect(
            [
              { "id" => "flu-a","name" => "Flu A" },
              nil,
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-b","name" => "Flu B" }
            ],
            {"lookup" => "name"}
          ).should eq(["Flu A", nil, "Flu A", "Flu B"])
        end
      end
    end

    context "using the root object" do
      describe "single values" do
        it "collects single values" do
          ManifestFieldMapping.new(manifest, nil, nil, " Hi there  \n\n ").collect(" Hi there  \n\n ", {"strip" => {"lookup" => "$"}}).should eq("Hi there")
        end
      end
    end
  end
end
