require 'spec_helper'

describe InstitutionsController do
  setup_fixtures do
    @user = User.make!
  end

  before(:each) {sign_in user}

  context "index" do

    let!(:institution)   { Institution.make! user: user }
    let!(:other_institution) { Institution.make! }

    it "should list insitutions" do
      institution2 = Institution.make! user: user
      get :index
      expect(response).to be_success
      expect(assigns(:institutions)).to contain_exactly(institution, institution2)
    end

    it "should redirect to edit institution if there is only one institution" do
      get :index
      expect(response).to be_redirect
    end

  end

  context "create" do

    it "institution is created if name is provided" do
      post :create, {"institution" => {"name" => "foo"}}
      expect(Institution.count).to eq(1)
    end

    it "institution is created with a blank invitation id" do
      post :create, {"institution" => {"name" => "foo", "pending_institution_invite_id" => ""}}
      expect(Institution.count).to eq(1)
    end

    it "institutions without name are not created" do
      post :create, {"institution" => {"name" => ""}}
      expect(Institution.count).to eq(0)
    end

    it "sets the newly created institution in context (#796)" do
      post :create, {"institution" => {"name" => "foo"}}
      expect(user.reload.last_navigation_context).to eq(Institution.last.uuid)
    end

    context "institution invite" do
      it "create with invite" do
        invite = PendingInstitutionInvite.make!(invited_user_email: user.email)
        post :create, {institution: {name: invite.institution_name, kind: invite.institution_kind, pending_institution_invite_id: invite.id}}

        institution = Institution.last
        expect(response).to redirect_to root_path(context: institution.uuid)
        expect(institution.name).to eq invite.institution_name
        expect(institution.kind).to eq invite.institution_kind

        invite.reload
        expect(invite).not_to be_is_pending
      end

      it "create with invite, overwriting name and type" do
        invite = PendingInstitutionInvite.make!(invited_user_email: user.email)
        post :create, {institution: {name: "Institution Override", kind: "manufacturer", pending_institution_invite_id: invite.id}}

        institution = Institution.last
        expect(response).to redirect_to root_path(context: institution.uuid)
        expect(institution.name).to eq "Institution Override"
        expect(institution.kind).to eq "manufacturer"

        invite.reload
        expect(invite).not_to be_is_pending
      end

      it "create with invite, not invited user" do
        invite = PendingInstitutionInvite.make!
        post :create, {institution: {name: invite.institution_name, kind: invite.institution_kind, pending_institution_invite_id: invite.id}}

        institution = Institution.last
        expect(response).to redirect_to root_path(context: institution.uuid)

        invite.reload
        expect(invite).to be_is_pending
      end

      it "fails if invite already accepted" do
        invite = PendingInstitutionInvite.make!(invited_user_email: user.email, status: "accepted")
        expect do
          post :create, {institution: {name: invite.institution_name, kind: invite.institution_kind, pending_institution_invite_id: invite.id}}
        end.to raise_error(ActionView::MissingTemplate)
      end
    end
  end

  context "new" do

    it "gets new page when there are no institutions" do
      get :new
      expect(response).to be_success
    end

    it "gets new page when there is one institution" do
      Institution.make! user: user
      get :new
      expect(response).to be_success
    end

    it "gets new page when there are many institutions" do
      2.times { Institution.make! user: user }
      get :new
      expect(response).to be_success
    end

  end

  describe "new_from_invite_data" do
    it "with invite" do
      invite = PendingInstitutionInvite.make!(invited_user_email: user.email)
      get :new_from_invite_data, {pending_institution_invite_id: invite.id}
      expect(response).to be_success
    end

    it "without invite" do
      expect do
        get :new_from_invite_data
      end.to raise_error(ActionView::MissingTemplate)
    end

    it "with accepted invite" do
      invite = PendingInstitutionInvite.make!(status: "accepted", invited_user_email: user.email)
      expect do
        get :new_from_invite_data, {pending_institution_invite_id: invite.id}
      end.to raise_error(ActionView::MissingTemplate)
    end

    it "gets redirect from other page when pending invitation" do
      dummy_institution = Institution.make! # there must be some institution in the database for the redirect to trigger
      invite = PendingInstitutionInvite.make!(invited_user_email: user.email)
      session[:pending_invite_id] = invite.id
      get :index
      expect(response).to redirect_to new_from_invite_data_institutions_path(pending_institution_invite_id: invite.id)
    end
  end
end
