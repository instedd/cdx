require 'spec_helper'

describe Manifest do
  it "creates a device model named according to the manifest" do
    manifest = '{"models" : ["foo"]}'
    Manifest.create(definition: manifest)

    Manifest.count.should eq(1)
    Manifest.first.definition.should eq(manifest)
    Model.count.should eq(1)
    Manifest.first.models.first.name.should eq("foo")
  end

  it "updates it's version number" do
    Manifest.create(definition: '{"models" : ["foo"], "version" : 1}')

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = '{"models" : ["foo"], "version" : 2}'
    manifest.save!

    Manifest.count.should eq(1)
    Model.count.should eq(1)
    Manifest.first.version.should eq(2)
  end

  it "leaves no orphan model" do
    Manifest.create(definition: '{"models" : ["foo"], "version" : 1}')

    Manifest.count.should eq(1)
    Model.count.should eq(1)
    Manifest.first.destroy()
    Manifest.count.should eq(0)
    Model.count.should eq(0)

    Manifest.create(definition: '{"models" : ["foo"], "version" : 1}')
    Manifest.create(definition: '{"models" : ["bar"], "version" : 1}')

    Manifest.count.should eq(2)
    Model.count.should eq(2)
    Manifest.first.destroy()
    Manifest.count.should eq(1)
    Model.count.should eq(1)

    Manifest.first.models.first.should eq(Model.first)

    manifest = Manifest.first

    manifest.version.should eq(1)
    manifest.definition = '{"models" : "foo", "version" : 2}'
    manifest.save!
    Model.count.should eq(1)

    Manifest.first.models.first.should eq(Model.first)
    Model.first.name.should eq("foo")
  end
end
