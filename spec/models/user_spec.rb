require 'spec_helper'

RSpec.describe User, type: :model do
  describe '.full_name' do
    it 'concatenates the users first and last name' do
      user = User.make(first_name: 'Roger', last_name: 'Melly')
      expect(user.full_name).to eq('Roger Melly')
    end
  end

  describe '.invited_pending?' do
    context 'when outstanding invitation' do
      let(:user) { User.make(:invited_pending) }
      it 'is truthy' do
        expect(user.invited_pending?).to be_truthy
      end
    end

    context 'when no outstanding invitation' do
      let(:user) { User.make }
      it 'is falsey' do
        expect(user.invited_pending?).to be_falsey
      end
    end
  end
end
