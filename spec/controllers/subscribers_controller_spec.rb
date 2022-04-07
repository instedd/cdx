require 'spec_helper'

describe SubscribersController, elasticsearch: true do
  setup_fixtures do
    @user = User.make!
    @institution = Institution.make! user: @user
  end

  before(:each) { sign_in user }

  context "with filters" do
    let!(:filter) { Filter.make! user: user, query: { site: 1 } }
    let(:subscriber) { Subscriber.make! user: user, filter: filter, fields: ['foo', 'bar'] }

    it "list subscribers" do
      subscriber
      get :index, format: :json
      expect(response.body).to eq([subscriber].to_json)
    end

    it "new" do
      get :new
      expect(response).to be_success
    end

    it "creates a subscriber" do
      post :create, format: :json, params: { filter_id: filter.id, subscriber: { name: "foo", url: "http://foo.com", fields: %w(foo bar) } }
      subscriber = filter.subscribers.first
      expect(subscriber.name).to eq("foo")
      expect(subscriber.url).to eq("http://foo.com")
      expect(subscriber.fields).to eq(["foo", "bar"])
    end

    it "deletes a subscriber" do
      delete :destroy, params: { filter_id: filter.id, id: subscriber.id }
      expect(filter.subscribers.count).to be(0)
    end
  end

  context "without filters" do
    it "redirects to subscribers on new, if there are no filters" do
      get :new
      expect(response).to redirect_to(subscribers_path)
    end
  end
end
