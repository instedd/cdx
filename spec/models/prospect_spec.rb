require 'spec_helper'

RSpec.describe Prospect, type: :model do
  describe 'Validations' do
    it 'is not valid without an :email' do
      expect(Prospect.make_unsaved(email: nil)).to_not be_valid
    end
  end

  describe 'Callbacks' do
    it 'is created with a unique UUID' do
      prospect_one = Prospect.make
      prospect_two = Prospect.make
      expect(prospect_one.uuid.size).to eq(36)
      expect(prospect_two.uuid.size).to eq(36)
      expect(prospect_one.uuid).to_not eq(prospect_two.uuid)
    end
  end
end
