RSpec.shared_context "cdx api helpers" do

  def query(query)
    Cdx::Api::Elasticsearch::Query.new(query.with_indifferent_access).execute
  end

  def query_tests(query_or_response)
    query_or_response[:response] || query(query_or_response)["tests"]
  end

  def time(year, month, day, hour = 12, minute = 0, second = 0)
    Time.local(year, month, day, hour, minute, second).iso8601
  end

  def expect_one_result(result, query_or_response)
    response = query_tests(query_or_response)

    expect(response.size).to eq(1)
    expect(response.first["results"].first["result"]).to eq(result)
  end

  def expect_one_result_with_field(key, value, query_or_response)
    response = query_tests(query_or_response)

    expect(response.size).to eq(1)
    expect(response.first[key]).to eq(value)
  end

  def expect_one(query_or_response)
    response = query_tests(query_or_response)

    expect(response.size).to eq(1)
    yield response.first
  end

  def expect_no_results(query_or_response)
    response = query_tests(query_or_response)
    expect(response).to be_empty
  end

end
