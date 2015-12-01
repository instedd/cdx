require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { User.make }
  let!(:institution)   { user.institutions.make }

  before do
    sign_in user
  end

  describe 'PUT toggle_access' do
    let(:user_inactive) { User.make(is_active: false) }
    let(:user_active) { User.make(is_active: true) }

    context 'when user is active' do
      it 'de-activates their account' do
        put :toggle_access, user_id: user_active.id
        user_active.reload
        expect(user_active.is_active?).to be_falsey
      end
    end

    context 'when user is active' do
      it 'activates their account' do
        put :toggle_access, user_id: user_inactive.id
        user_inactive.reload
        expect(user_inactive.is_active?).to be_truthy
      end
    end
  end
end
