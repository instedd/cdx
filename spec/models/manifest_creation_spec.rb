require 'spec_helper'

describe Manifest do

  context "creation" do

    let (:definition) do
      %{{
        "metadata" : {
          "conditions": ["mtb", "riff"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}
    end

    it "updates its version number" do
      updated_definition = %{{
        "metadata" : {
          "conditions": ["mtb"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : "2.0.1",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      Manifest.make!(definition: definition)

      manifest = Manifest.first

      expect(manifest.version).to eq("1")
      manifest.definition = updated_definition
      manifest.save!

      expect(Manifest.count).to eq(1)
      expect(DeviceModel.count).to eq(1)
      expect(Manifest.first.version).to eq("2.0.1")
    end

    it "updates its api_version number" do
      updated_definition = %{{
        "metadata" : {
          "api_version" : "9.9.9",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      Manifest.new(device_model: DeviceModel.make!, definition: definition).save(:validate => false)

      manifest = Manifest.first

      expect(manifest.api_version).to eq(Manifest::CURRENT_VERSION)
      manifest.definition = updated_definition
      manifest.save(:validate => false)

      expect(Manifest.count).to eq(1)
      expect(DeviceModel.count).to eq(1)
      expect(Manifest.first.api_version).to eq("9.9.9")
    end

    it "returns all the valid manifests" do
      Manifest.new(definition: %{{
        "metadata" : {
          "api_version" : "0.1.1",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}).save(:validate => false)

      manifest = Manifest.make! device_model: DeviceModel.make!

      expect(Manifest.valid).to eq([manifest])
    end

    it "leaves device models after being deleted" do
      Manifest.make! definition: definition

      Manifest.first.destroy

      expect(Manifest.count).to eq(0)
      expect(DeviceModel.count).to eq(1)
    end

    it "ensures one manifest per device model" do
      Manifest.create!(device_model: DeviceModel.make!(name: 'bar'), definition: definition)

      expect(Manifest.count).to eq(1)
      expect(DeviceModel.count).to eq(1)

      Manifest.create(device_model: DeviceModel.first, definition: definition)

      expect(Manifest.count).to eq(1)
      expect(DeviceModel.count).to eq(1)
    end

    it "creates conditions from manifest" do
      Manifest.make!(definition: definition)

      conditions = Condition.all
      expect(conditions.count).to eq(2)
      expect(conditions.map(&:name).sort).to eq(["mtb", "riff"])

      expect(Manifest.first.conditions.count).to eq(2)
    end

    it "errors if condition is not in snake case" do
      definition = %{{
        "metadata" : {
          "conditions": ["MTB"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      manifest = Manifest.create(device_model: DeviceModel.make!, definition: definition)
      expect(manifest).not_to be_valid
      expect(manifest.errors[:conditions]).to eq(["must be in snake case: MTB"])
    end
  end
end
