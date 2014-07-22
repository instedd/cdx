require 'spec_helper'

describe Cdx::Api do
  def index(body)
    Cdx::Api.client.index index: "cdx_events", type: "event", body: body, refresh: true
  end

  def get_updates(query)
    Cdx::Api.query(query.with_indifferent_access)
  end

  def time(year, month, day, hour = 12, minute = 0, second = 0)
    Time.utc(year, month, day, hour, minute, second).iso8601
  end

  it "should check for new events since a date" do
    index results: [result: :positive], created_at: time(2013, 1, 1)
    index results: [result: :negative], created_at: time(2013, 1, 2)

    response = get_updates(since: time(2013, 1, 2))

    expect(response.size).to eq(1)
    expect(response.first["results"].first["result"]).to eq("negative")

    response = get_updates(since: time(2013, 1, 1))

    expect(response.first["results"].first["result"]).to eq("positive")
    expect(response.last["results"].first["result"]).to eq("negative")

    expect(get_updates(since: time(2013, 1, 3))).to be_empty
  end
end
