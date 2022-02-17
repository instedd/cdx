require 'spec_helper'

describe AssayAttachment do
  it "validates presence of loinc_code" do
    expect(AssayAttachment.new).to validate_presence_of(:loinc_code)
  end

  it "validates presence of result or file" do
    attachment = AssayAttachment.make_unsaved(result: nil, assay_file: nil)
    attachment.validate
    expect(attachment.errors).to have_key(:result)
    expect(attachment.errors).to have_key(:assay_file)
    attachment.result = "foo bar"
    attachment.validate
    expect(attachment.errors).to be_empty
  end
end
