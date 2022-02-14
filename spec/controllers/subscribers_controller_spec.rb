require 'spec_helper'

describe SubscribersController, elasticsearch: true do
  let(:user) { User.make! }
  let!(:institution) { Institution.make!(user: user) }
  before(:each) { sign_in user }

  context "with filters" do
    let(:filter) { Filter.make! user: user, query: { site: 1 } }

    it "list subscribers" do
      subscriber = Subscriber.make! user: user, filter: filter, fields: ['foo', 'bar']
      get :index, format: :json
      expect(response.body).to eq([subscriber].to_json)
    end

    it "creates a subscriber" do
      post :create, format: :json, filter_id: filter.id, subscriber: { name: "foo", url: "http://foo.com", fields: %w(foo bar) }
      subscriber = filter.subscribers.first
      expect(subscriber.name).to eq("foo")
      expect(subscriber.url).to eq("http://foo.com")
      expect(subscriber.fields).to eq(["foo", "bar"])
    end

    it "deletes a subscriber" do
      subscriber = Subscriber.make! user: user, filter: filter, fields: ['foo', 'bar']
      delete :destroy, filter_id: filter.id, id: subscriber.id
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
