require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { User.make }
  let!(:institution) { user.institutions.make }
  let(:default_params) { { context: institution.uuid } }

  before do
    sign_in user
  end
  
  let(:user_to_edit) { User.make }

  describe 'GET :edit' do
    before do
      get :edit, id: user_to_edit.id
    end
    it 'assigns an instance of :user_to_edit' do
      expect(assigns(:user)).to eq(user_to_edit)
    end

    it 'renders the :edit template' do
      expect(response).to render_template(:edit)
    end
  end

  describe 'PUT :update' do
    let(:user_params) { user_to_edit.attributes }
    let(:admin_user_params) { user.attributes }

    it 'assigns an instance of user' do
      put :update, id: user_to_edit.id, user: user_params
      expect(assigns(:user)).to eq(user_to_edit)
    end

    it 'does not change own (ie admin user) attributes' do
      admin_user_params[:is_active] = false
      put :update, id: user.id, user: admin_user_params
      expect(user.reload.is_active).to be_truthy
    end

    context 'when the is active box is unchecked' do
      it 'can suspend a users access' do
        user_params[:is_active] = false
        put :update, id: user_to_edit.id, user: user_params
        expect(user_to_edit.reload.is_active).to be_falsey
      end
    end
  end
end
