require 'spec_helper'

describe Manifest do

  context "creation" do

    let (:definition) do
      %{{
        "metadata" : {
          "device_models" : ["foo"],
          "conditions": ["MTB", "RIFF"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}
    end

    it "creates a device model named according to the manifest" do
      Manifest.create!(definition: definition)

      expect(Manifest.count).to eq(1)
      expect(Manifest.first.definition).to eq(definition)
      expect(DeviceModel.count).to eq(1)
      expect(Manifest.first.device_models.first.name).to eq("foo")
    end

    it "updates its version number" do
      updated_definition = %{{
        "metadata" : {
          "device_models" : ["foo"],
          "conditions": ["MTB"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : "2.0.1",
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      Manifest.create!(definition: definition)

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
          "device_models" : ["foo"],
          "api_version" : "9.9.9",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      Manifest.new(definition: definition).save(:validate => false)

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
          "device_models" : ["foo"],
          "api_version" : "0.1.1",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}).save(:validate => false)

      manifest = Manifest.create!(definition: definition)

      expect(Manifest.valid).to eq([manifest])
    end

    it "reuses an existing device model if it already exists" do
      Manifest.create definition: definition
      Manifest.first.destroy

      model = DeviceModel.first

      Manifest.create definition: definition

      expect(DeviceModel.count).to eq(1)
      expect(DeviceModel.first.id).to eq(model.id)
    end

    it "leaves device models after being deleted" do
      Manifest.create definition: definition

      Manifest.first.destroy

      expect(Manifest.count).to eq(0)
      expect(DeviceModel.count).to eq(1)
    end

    it "leaves no orphan model" do
      Manifest.create!(definition: definition)

      expect(Manifest.count).to eq(1)
      expect(DeviceModel.count).to eq(1)
      Manifest.first.destroy()
      expect(Manifest.count).to eq(0)

      Manifest.create!(definition: definition)

      definition_bar = %{{
        "metadata" : {
          "version" : 1,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["bar"],
          "conditions": ["MTB"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      Manifest.create!(definition: definition_bar)

      expect(Manifest.count).to eq(2)
      expect(DeviceModel.count).to eq(2)
      Manifest.first.destroy()
      expect(Manifest.count).to eq(1)
      expect(DeviceModel.count).to eq(2)

      definition_version = %{{
        "metadata" : {
          "version" : 2,
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "device_models" : ["foo"],
          "conditions": ["MTB"],
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}

      manifest = Manifest.first

      expect(manifest.version).to eq("1")
      manifest.definition = definition_version
      manifest.save!

      expect(DeviceModel.count).to eq(2)

      expect(Manifest.first.device_models.first).to eq(DeviceModel.first)
      expect(DeviceModel.first.name).to eq("foo")
    end

    it "creates conditions from manifest" do
      Manifest.create!(definition: definition)

      conditions = Condition.all
      expect(conditions.count).to eq(2)
      expect(conditions.map(&:name).sort).to eq(["MTB", "RIFF"])

      expect(Manifest.first.conditions.count).to eq(2)
    end
  end
end
