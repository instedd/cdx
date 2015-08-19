require 'spec_helper'

describe ManifestFieldMapping do
  describe "clusterisation" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil, nil) }

    describe "single values" do
      it "clusterises values lower than lower bound" do
        expect(mapping.clusterise(1, [5, 20, 40])).to eq("<5")
      end

      it "clusterises negative values" do
        expect(mapping.clusterise(-1, [5, 20, 40])).to eq("<5")
      end

      it "clusterises values lower than lower bound" do
        expect(mapping.clusterise(-1, [-5, 5, 20, 40])).to eq("-5-5")
      end

      it "clusterises values lower than lower bound" do
        expect(mapping.clusterise(-10, [-5, 5, 20, 40])).to eq("<-5")
      end

      it "clusterises values greater than upper bound" do
        expect(mapping.clusterise(42, [5, 20, 40])).to eq("40+")
      end

      it "clusterises nil" do
        expect(mapping.clusterise(nil, [5, 20, 40])).to eq(nil)
      end
    end

    describe "multiple values" do
      it "clusterises an empty list" do
        expect(mapping.clusterise([], [5, 20, 40])).to eq([])
      end

      it "clusterises a list with a single value" do
        expect(mapping.clusterise([7], [5, 20, 40])).to eq(["5-20"])
      end

      it "clusterises a list with multiple values" do
        expect(mapping.clusterise([8, 6, 56], [5, 20, 40])).to eq(["5-20", "5-20", "40+"])
      end

      it "clusterises a list with duplicated values" do
        expect(mapping.clusterise([8, 6, 56, 8], [5, 20, 40])).to eq(["5-20", "5-20", "40+", "5-20"])
      end

      it "clusterises a list with nil values" do
        expect(mapping.clusterise([8, 6, nil, 56, 8], [5, 20, 40])).to eq(["5-20", "5-20", nil, "40+", "5-20"])
      end
    end
  end

  describe "strip" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil, nil) }

    describe "single values" do
      it "stripes an empty string" do
        expect(mapping.strip("")).to eq("")
      end

      it "stripes a blank string" do
        expect(mapping.strip(" ")).to eq("")
      end

      it "stripes a blank string" do
        expect(mapping.strip("       ")).to eq("")
      end

      it "stripes newlines" do
        expect(mapping.strip("\n")).to eq("")
      end

      it "stripes nil" do
        expect(mapping.strip(nil)).to eq(nil)
      end

      it "stripes an stripped string" do
        expect(mapping.strip("hi there")).to eq("hi there")
      end

      it "stripes a non-empty string" do
        expect(mapping.strip(" hi there        ")).to eq("hi there")
      end

      it "stripes newlines from non-empty strings" do
        expect(mapping.strip("\n\n hi there \n   \n")).to eq("hi there")
      end
    end

    describe "multiple values" do
      it "strips an empty list" do
        expect(mapping.strip([])).to eq([])
      end

      it "strips a list with a single value" do
        expect(mapping.strip([" hi there "])).to eq(["hi there"])
      end

      it "strips a list with multiple values" do
        expect(mapping.strip([" hi there ", "hi", "", "\n\nhi "])).to eq(["hi there", "hi", "", "hi"])
      end

      it "strips a list with duplicated values" do
        expect(mapping.strip([" hi there ", "hi", "", "\n\nhi ", "hi", " hi there "])).to eq(["hi there", "hi", "", "hi", "hi", "hi there"])
      end

      it "strips a list with nil values" do
        expect(mapping.strip([" hi there ", "hi", nil, "", "\n\nhi ", "hi", " hi there "])).to eq(["hi there", "hi", nil, "", "hi", "hi", "hi there"])
      end
    end
  end

  describe "lowercase" do
    let(:mapping) { ManifestFieldMapping.new(nil, nil, nil, nil) }

    describe "single values" do
      it "downcase an empty string" do
        expect(mapping.lowercase("")).to eq("")
      end

      it "downcase a lowercase string" do
        expect(mapping.lowercase("foo")).to eq("foo")
      end

      it "downcase nil" do
        expect(mapping.lowercase(nil)).to eq(nil)
      end

      it "downcase an uppercase string" do
        expect(mapping.lowercase("FOO")).to eq("foo")
      end

      it "downcase an uppercase string" do
        expect(mapping.lowercase("Foo")).to eq("foo")
      end

      it "downcase an uppercase string" do
        expect(mapping.lowercase("Foo Bar Baz")).to eq("foo bar baz")
      end
    end

    describe "multiple values" do
      it "downcase an empty list" do
        expect(mapping.lowercase([])).to eq([])
      end

      it "downcase a list with a single value" do
        expect(mapping.lowercase(["HI ThERe "])).to eq(["hi there "])
      end

      it "downcase a list with multiple values" do
        expect(mapping.lowercase(["Hi There", "hi", "", "\n\nHI "])).to eq(["hi there", "hi", "", "\n\nhi "])
      end

      it "downcase a list with duplicated values" do
        expect(mapping.lowercase(["Hi There", "hi", "","Hi There", "Hi"])).to eq(["hi there", "hi", "", "hi there", "hi"])
      end

      it "downcase a list with nil values" do
        expect(mapping.lowercase(["Hi There", "hi", nil,"Hi There", "Hi"])).to eq(["hi there", "hi", nil, "hi there", "hi"])
      end
    end
  end

  describe "map" do
    let(:manifest) {
      manifest = double()
      allow(manifest).to receive(:parser) { JsonMessageParser.new }
      manifest
    }

    context "without using root object" do
      let(:mapping) {
        ManifestFieldMapping.new(manifest, nil, nil, nil)
      }

      describe "works as identity for single values" do
        it "collects single values" do
          expect(mapping.map({ "id" => "flu-a","name" => "Flu A" }, {"lookup" => "name"})).to eq("Flu A")
        end

        it "collects nil values" do
          expect(mapping.map(nil, {"lookup" => "name"})).to eq(nil)
        end
      end

      describe "multiple values" do
        it "collects an empty list" do
          expect(mapping.map([], {"lookup" => "name"})).to eq([])
        end

        it "collects a list with a single value" do
          expect(mapping.map([ { "id" => "flu-a","name" => "Flu A" } ], {"lookup" => "name"})).to eq(["Flu A"])
        end

        it "collects a list with multiple values" do
          expect(mapping.map(
            [
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-b","name" => "Flu B" }
            ],
            {"lookup" => "name"}
          )).to eq(["Flu A", "Flu B"])
        end

        it "collects a list with duplicated values" do
          expect(mapping.map(
            [
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-b","name" => "Flu B" }
            ],
            {"lookup" => "name"}
          )).to eq(["Flu A", "Flu A", "Flu B"])
        end

        it "clusterises a list with nil values" do
          expect(mapping.map(
            [
              { "id" => "flu-a","name" => "Flu A" },
              nil,
              { "id" => "flu-a","name" => "Flu A" },
              { "id" => "flu-b","name" => "Flu B" }
            ],
            {"lookup" => "name"}
          )).to eq(["Flu A", nil, "Flu A", "Flu B"])
        end
      end
    end

    context "using the root object" do
      describe "single values" do
        it "collects single values" do
          expect(ManifestFieldMapping.new(manifest, nil, nil, " Hi there  \n\n ").map(" Hi there  \n\n ", {"strip" => {"lookup" => "$"}})).to eq("Hi there")
        end
      end
    end
  end
end
