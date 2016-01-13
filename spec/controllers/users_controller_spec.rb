require 'spec_helper'

describe UsersController, type: :controller do
  let(:user) { User.make }
  let!(:institution) { user.institutions.make }
  let(:default_params) { { context: institution.uuid } }

  before do
    user.grant_superadmin_policy
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

  describe 'POST create' do
    let(:role) { institution.roles.first }

    after(:each) { ActionMailer::Base.deliveries.clear }

    it "sends an invitation to a new user" do
      post :create, {users: 'new@example.com', role: role.id}
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "sends mutiple invitations to new users" do
      post :create, {users: 'new@example.com, second@example.com', role: role.id}
      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end

    it "adds role to existing users" do
      post :create, {users: user_to_edit.email, role: role.id}
      expect(user_to_edit.roles.count).to eq(1)
      expect(user_to_edit.roles.first).to eq(role)
    end

    it "adds role to new user" do
      post :create, {users: 'new@example.com', role: role.id}
      new_user = User.find_by_email('new@example.com')
      expect(new_user.roles.count).to eq(1)
      expect(new_user.roles.first).to eq(role)
    end

    it "does not add duplicate roles to users" do
      user_to_edit.roles << role
      post :create, {users: user_to_edit.email, role: role.id}
      expect(user_to_edit.roles.count).to eq(1)
    end

    it "refreshes computed policies" do
      expect(user_to_edit.computed_policies.count).to eq(1)
      post :create, {users: user_to_edit.email, role: role.id}
      expect(user_to_edit.computed_policies.count).to_not eq(1)
    end
  end

end
