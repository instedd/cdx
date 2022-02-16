require 'spec_helper'

describe AssayAttachment do
  it "validates presence of loinc_code" do
    expect(AssayAttachment.new).to validate_presence_of(:loinc_code)
  end
end
