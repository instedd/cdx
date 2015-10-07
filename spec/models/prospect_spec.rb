require 'spec_helper'

RSpec.describe Prospect, type: :model do
  describe 'Validations' do
    it 'is not valid without an :email' do
      expect(Prospect.make_unsaved(email: nil)).to_not be_valid
    end
  end
end
