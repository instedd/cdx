require 'spec_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '.last_activity' do
    describe 'last login time' do
      let(:last_login) { 4.hours.ago }
      let(:date_formatted) { last_login.to_formatted_s(:long) }
      let(:user) { User.make(last_sign_in_at: last_login) }
      it 'returns formatted date' do
        expect(helper.last_activity(user)).to eq(date_formatted)
      end
    end
    context 'when the user has an outstanding invitation' do
      let(:date) { 1.month.ago }
      let(:date_formatted) { date.to_formatted_s(:long) }
      let(:user) { User.make(:invited_pending, invitation_created_at: date) }
      it 'returns Invitation sent with a formatted date string' do
        expect(helper.last_activity(user)).to eq("Invitation sent #{date_formatted}")
      end
    end

    context 'when the user has never logged in' do
      let(:user) { User.make(last_sign_in_at: nil) }
      it 'returns Never logged in' do
        expect(helper.last_activity(user)).to eq('Never logged in')
      end
    end
  end
end
