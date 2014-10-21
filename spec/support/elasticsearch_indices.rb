RSpec.shared_context "elasticsearch index" do

  before(:each) do
    Cdx::Api.client.delete_by_query index: "cdx_events", body: { query: { match_all: {} } } rescue nil
  end

  after(:each) do
    Cdx::Api.client.delete_by_query index: "cdx_events", body: { query: { match_all: {} } } rescue nil
  end

  def index(body)
    Cdx::Api.client.index index: "cdx_events", type: "event", body: body, refresh: true
  end

end
