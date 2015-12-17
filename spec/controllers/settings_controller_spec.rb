require 'spec_helper'

RSpec.describe SettingsController, type: :controller do
  let(:user) { User.make }
  let!(:institution) { user.institutions.make }
  let(:default_params) { { context: institution.uuid } }

  before do
    sign_in user
  end

  describe 'GET #edit' do
    before do
      get :edit
    end

    it 'has a 200 resonse status' do
      expect(response.status).to eq(200)
    end

    it 'renders the :edit template' do
      expect(response).to render_template(:edit)
    end

    it 'assigns an array of locales' do
      expect(assigns(:locales)).to be_a(Array)
    end
  end

  describe 'PATCH #update' do
    let(:params) do
      {
        'user' => {
          locale: 'de',
          time_zone: 'Berlin',
          timestamps_in_device_time_zone: true
        }
      }
    end

    before do
      patch :update, params
    end

    it 'updates the users settings' do
      user.reload
      expect(user.locale).to eq('de')
      expect(user.time_zone).to eq('Berlin')
      expect(user.timestamps_in_device_time_zone).to be_truthy
    end
  end
end
