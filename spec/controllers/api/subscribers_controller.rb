require 'spec_helper'

describe Api::SubscribersController, elasticsearch: true do
  let(:user) { User.make }
  let!(:institution) { user.create Institution.make_unsaved }
  let(:filter) { user.filters.make query: { site: 1 } }
  before(:each) { sign_in user }

  it "list subscribers" do
    subscriber = filter.subscribers.make fields: ['foo', 'bar']
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
    subscriber = filter.subscribers.make fields: ['foo', 'bar']
    delete :destroy, filter_id: filter.id, id: subscriber.id
    expect(filter.subscribers.count).to be(0)
  end
end
