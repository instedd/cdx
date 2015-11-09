require 'spec_helper'

RSpec.describe User, type: :model do
  describe ':full_name' do
    it 'concatenates the users first and last name' do
      user = User.make(first_name: 'Roger', last_name: 'Melly')
      expect(user.full_name).to eq('Roger Melly')
    end
  end
end
