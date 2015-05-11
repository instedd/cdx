require 'spec_helper'

describe SubscribersController do
  let(:user) { User.make }
  let(:filter) { user.filters.make query: { laboratory: 1 } }
  before(:each) { sign_in user }

  it "list subscribers" do
    subscriber = filter.subscribers.make fields: ['foo', 'bar']
    get :index, format: :json
    response.body.should eq([subscriber].to_json)
  end

  it "creates a subscriber" do
    post :create, format: :json, filter_id: filter.id, subscriber: { name: "foo", url: "http://foo.com", fields: %w(foo bar) }
    subscriber = filter.subscribers.first
    subscriber.name.should eq("foo")
    subscriber.url.should eq("http://foo.com")
    subscriber.fields.should eq(["foo", "bar"])
  end

  it "deletes a subscriber" do
    subscriber = filter.subscribers.make fields: ['foo', 'bar']
    delete :destroy, filter_id: filter.id, id: subscriber.id
    filter.subscribers.count.should be(0)
  end
end
