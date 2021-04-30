require 'spec_helper'

RSpec.describe LaboratorySample, type: :model do

  context "initialize" do

    it "should be asigned a UUID when created" do
      lab_sample = LaboratorySample.new

      expect(lab_sample.uuid).not_to be_empty
    end
  end
end
