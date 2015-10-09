require 'spec_helper'

RSpec.describe ProspectsController, type: :controller do
  describe 'GET #index' do
    let!(:prospects) do
      prospects = []
      prospects << UserRequest.make
      prospects << UserRequest.make
    end

    before do
      get :index
    end

    it 'has status code 200' do
      expect(response.status).to eq(200)
    end

    it 'renders the :index template' do
      expect(response).to render_template('prospects/index')
    end

    it 'assigns an array of Prospect objects' do
      expect(assigns(:prospects)).to eq(prospects)
    end
  end

  describe 'GET #new' do
    before do
      get :new
    end

    it 'has status code 200' do
      expect(response.status).to eq(200)
    end

    it 'renders the :new template' do
      expect(response).to render_template('prospects/new')
    end

    it 'assigns a new Prospect object' do
      expect(assigns(:prospect)).to be_a_new(UserRequest)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:prospect) do
        Prospect.make_unsaved.attributes
      end

      it 'adds a new :prospect request to the database' do
        expect do
          post :create, user_request: prospect
        end.to change(UserRequest, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 're-renders the :new action' do
        post :create, user_request: {}
        expect(response).to render_template(:new)
      end
    end
  end
end
