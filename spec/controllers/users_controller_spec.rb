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

    it "sends an invitation to a new user" do
      post :create, {users: ['new@example.com'], role: role.id}
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "sends mutiple invitations to new users" do
      post :create, {users: ['new@example.com', 'second@example.com'], role: role.id}
      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end

    it "adds role to existing users" do
      post :create, {users: [user_to_edit.email], role: role.id}
      expect(user_to_edit.roles.count).to eq(1)
      expect(user_to_edit.roles.first).to eq(role)
    end

    it "adds role to new user" do
      post :create, {users: ['new@example.com'], role: role.id}
      new_user = User.find_by_email('new@example.com')
      expect(new_user.roles.count).to eq(1)
      expect(new_user.roles.first).to eq(role)
    end

    it "does not add duplicate roles to users" do
      user_to_edit.roles << role
      post :create, {users: [user_to_edit.email], role: role.id}
      expect(user_to_edit.roles.count).to eq(1)
    end

    it "refreshes computed policies" do
      expect(user_to_edit.computed_policies.count).to eq(1)
      post :create, {users: [user_to_edit.email], role: role.id}
      expect(user_to_edit.computed_policies.count).to_not eq(1)
    end
  end

  describe "POST create_with_institution_invite" do
    it "sends an invitation to a new user" do
      expect do
        post :create_with_institution_invite, {
          user_invite_data: {email: "new@example.com"},
          institution_data: {name: "New Institution", type: "institution"},
        }
      end.to change{User.count}.by(1)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      user = User.find_by(email: "new@example.com")
      expect(user).to be_valid_invitation
    end

    it "sets first and last name of new user" do
      post :create_with_institution_invite, {
        user_invite_data: {email: "new@example.com", firstName: "New", lastName: "User" },
        institution_data: {name: "New Institution", type: "institution"},
      }
      expect(response).to be_success
      user = User.find_by(email: "new@example.com")
      expect(user.first_name).to eq "New"
      expect(user.last_name).to eq "User"
    end

    it "creates institution invite" do
      post :create_with_institution_invite, {
        user_invite_data: {email: "new@example.com" },
        institution_data: {name: "New Institution", type: "institution"},
      }
      invite = PendingInstitutionInvite.first
      expect(invite.invited_user_email).to eq "new@example.com"
      expect(invite.invited_by_user).to eq user
      expect(invite.institution_name).to eq "New Institution"
      expect(invite.institution_kind).to eq "institution"
      expect(invite).to be_is_pending
    end

    it "fails for empty institution name and kind" do
      expect do
        post :create_with_institution_invite, {
          user_invite_data: {email: "new@example.com" },
          institution_data: {name: "", type: "institution"},
        }
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Institution name can't be blank")

      expect do
        post :create_with_institution_invite, {
          user_invite_data: {email: "new@example.com" },
          institution_data: {name: "New Institution", type: ""},
        }
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Institution kind can't be blank, Institution kind is not included in the list")

      expect do
        post :create_with_institution_invite, {
          user_invite_data: {email: "new@example.com" },
          institution_data: {name: "New Institution", type: "foo"},
        }
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Institution kind is not included in the list")
    end

    it "fails for empty mail" do
      expect do
        post :create_with_institution_invite, {
          user_invite_data: {email: ""},
          institution_data: {name: "New Institution", type: "institution"},
        }
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Invited user email can't be blank")
    end

    it "rejects sending to multiple adresses (#1436)" do
      expect do
        post :create_with_institution_invite, {
          user_invite_data: {email: "new@example.com,other@example.com"},
          institution_data: {name: "New Institution", type: "institution"},
        }
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Invited user email is invalid")
    end

    context "existing user" do
      let!(:existing_user) { User.make }

      it "sends invitation" do
        expect do
          post :create_with_institution_invite, {
            user_invite_data: {email: existing_user.email},
            institution_data: {name: "New Institution", type: "institution"},
          }
        end.not_to change{User.count}
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(existing_user).not_to be_valid_invitation
      end

      it "doesn't change first and last name" do
        post :create_with_institution_invite, {
          user_invite_data: {email: existing_user.email, firstName: "New", lastName: "User" },
          institution_data: {name: "New Institution", type: "institution"},
        }
        expect(response).to be_success
        expect(existing_user.first_name).not_to eq "New"
        expect(existing_user.last_name).not_to eq "User"
      end
    end
  end

  describe "GET index" do

    let(:role) { Role.first }
    before(:each) do
      user_to_edit.roles << role
      user_to_edit.update_computed_policies
    end

    it "should load index as HTML" do
      get :index
      users = assigns(:users)
      expect(users).to eq([user_to_edit])
    end

    it "should return a valid CSV when requested" do
      get :index, format: :csv
      csv = CSV.parse(response.body)
      expect(csv[0]).to eq(["Full name", "Roles", "Last activity"])
      expect(csv[1]).to eq([user_to_edit.full_name,Role.first.name,"Never logged in"])
    end

    it "should filter by name" do
      another_user = User.make first_name: "lulululu"
      another_user.roles << role
      another_user.update_computed_policies

      get :index, name: "lululu"
      users = assigns(:users)
      expect(users).to eq([another_user])
    end

    it "should filter by role" do
      another_user = User.make
      expect(role).to_not eq(Role.last)
      another_user.roles << Role.last
      another_user.update_computed_policies

      get :index, role: role.id
      users = assigns(:users)
      expect(users).to eq([user_to_edit])
    end

    it "should filter by last activity" do
      another_user = User.make(:invited_pending)
      another_user.roles << role
      another_user.update_computed_policies
      user_to_edit.last_sign_in_at = 3.weeks.ago
      user_to_edit.save

      get :index, last_activity: "#{1.week.ago.strftime('%Y-%m-%d')} 00:00:00 UTC"
      users = assigns(:users)
      expect(users).to eq([another_user])
    end


  end

end
