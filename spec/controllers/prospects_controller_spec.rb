require 'spec_helper'

RSpec.describe ProspectsController, type: :controller do
  let!(:prospects) do
    prospects = []
    prospects << Prospect.make
    prospects << Prospect.make
  end

  describe 'GET #index' do
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
      expect(assigns(:prospects)).to eq(Prospect.pending)
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
      expect(assigns(:prospect)).to be_a_new(Prospect)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:prospect) do
        Prospect.make_unsaved.attributes
      end

      it 'adds a new :prospect request to the database' do
        expect do
          post :create, prospect: prospect
        end.to change(Prospect, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 're-renders the :new action' do
        post :create, prospect: {}
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #reject' do
    context 'with valid Prospect' do
      it 'Decrements pending prospect count' do
        expect do
          put :reject, id: prospects.first.uuid
        end.to change(Prospect.pending, :count).by(-1)
      end
    end
  end

  describe 'PUT #approve' do
    context 'with valid Prospect' do
      it 'creates a new User' do
        expect do
          put :approve, id: prospects.first.uuid
        end.to change(User, :count).by(1)
      end
    end

    context 'with non-existant Prospect' do
      it 'does not create a new User' do
        expect do
          put :approve, id: SecureRandom.uuid
        end.to change(User, :count).by(0)
      end
    end
  end
end
