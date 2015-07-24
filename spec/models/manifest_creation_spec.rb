require 'spec_helper'

describe Manifest do

  context "creation" do

    let (:definition) do
      %{{
        "metadata" : {
          "device_models" : ["foo"],
          "conditions": ["MTB"],
          "api_version" : "#{Manifest::CURRENT_VERSION}",
          "version" : 1,
          "source" : {"type" : "json"}
        },
        "field_mapping" : {}
      }}
    end

    it "creates a device model named according to the manifest" do
      Manifest.create!(definition: definition)

      Manifest.count.should eq(1)
      Manifest.first.definition.should eq(definition)
      DeviceModel.count.should eq(1)
      Manifest.first.device_models.first.name.should eq("foo")
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

      manifest.version.should eq("1")
      manifest.definition = updated_definition
      manifest.save!

      Manifest.count.should eq(1)
      DeviceModel.count.should eq(1)
      Manifest.first.version.should eq("2.0.1")
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

      manifest.api_version.should eq(Manifest::CURRENT_VERSION)
      manifest.definition = updated_definition
      manifest.save(:validate => false)

      Manifest.count.should eq(1)
      DeviceModel.count.should eq(1)
      Manifest.first.api_version.should eq("9.9.9")
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

      Manifest.valid.should eq([manifest])
    end

    it "reuses an existing device model if it already exists" do
      Manifest.create definition: definition
      Manifest.first.destroy

      model = DeviceModel.first

      Manifest.create definition: definition

      DeviceModel.count.should eq(1)
      DeviceModel.first.id.should eq(model.id)
    end

    it "leaves device models after being deleted" do
      Manifest.create definition: definition

      Manifest.first.destroy

      Manifest.count.should eq(0)
      DeviceModel.count.should eq(1)
    end

    it "leaves no orphan model" do
      Manifest.create!(definition: definition)

      Manifest.count.should eq(1)
      DeviceModel.count.should eq(1)
      Manifest.first.destroy()
      Manifest.count.should eq(0)

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

      Manifest.count.should eq(2)
      DeviceModel.count.should eq(2)
      Manifest.first.destroy()
      Manifest.count.should eq(1)
      DeviceModel.count.should eq(2)

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

      manifest.version.should eq("1")
      manifest.definition = definition_version
      manifest.save!

      DeviceModel.count.should eq(2)

      Manifest.first.device_models.first.should eq(DeviceModel.first)
      DeviceModel.first.name.should eq("foo")
    end
  end
end
