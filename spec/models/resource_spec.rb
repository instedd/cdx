require 'spec_helper'
include Policy::Actions

describe Resource do

  it "should parse a resource string" do
    expect(Resource.resolve("institution")).to eq([Institution, nil, {}])
  end

  it "should parse a resource string ending in slash" do
    expect(Resource.resolve("institution/")).to eq([Institution, nil, {}])
  end

  it "should parse a resource string with star" do
    expect(Resource.resolve("institution/*")).to eq([Institution, nil, {}])
  end

  it "should parse a resource string with id" do
    expect(Resource.resolve("institution/1")).to eq([Institution, "1", {}])
  end

  it "should parse a resource string with conditions" do
    expect(Resource.resolve("institution?site=1")).to eq([Institution, nil, {"site" => "1"}])
  end

end
