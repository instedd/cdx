require 'spec_helper'

RSpec.describe Users::InvitationsController, type: :controller do
  include Devise::TestHelpers

  describe 'Inheritance' do
    it 'inherits from Devise::InvitationsCotroller' do
      expect(described_class).to be < Devise::InvitationsController
    end
  end

  describe 'GET #new' do
    before do
      get :new
    end

    xit 'initializes and assigns a new User instance' do
    end

    xit 'renders the new template' do
      expect(response).to render_template('users/invitations/new')
    end
  end
end
