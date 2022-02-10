require "spec_helper"

RSpec.describe Users::InvitationsController, type: :controller do
  let!(:new_user) {
    User.make(:invited_pending).tap do |user|
      user.send("generate_invitation_token!")
    end
  }
  let(:invite) { PendingInstitutionInvite.make }

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "accept" do
    it "accepts pending institution invite" do
      get :edit, {:invitation_token => new_user.raw_invitation_token, :pending_institution_invite_id => invite.id}
      expect(session[:pending_invite_id]).to eq invite.id.to_s
      # not testing anythinge else here because the main behaviour is defined by devise
    end
  end
end
