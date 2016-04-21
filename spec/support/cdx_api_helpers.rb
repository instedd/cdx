RSpec.shared_context "cdx api helpers" do
  def query(query)
    Cdx::Api::Elasticsearch::Query.new(query, Cdx::Fields.test).execute
  end

  def query_tests(query_or_response)
    query_or_response[:response] || query(query_or_response)["tests"]
  end

  def time(year, month, day, hour = 12, minute = 0, second = 0)
    Time.local(year, month, day, hour, minute, second).iso8601
  end

  def expect_one_result(result, query_or_response)
    expect_one(query_or_response) do |response|
      expect(response["test"]["assays"].first["result"]).to eq(result)
    end
  end

  def expect_one_event_with_field(scope, key, value, query_or_response)
    expect_one(query_or_response) do |response|
      expect(response[scope][key]).to eq(value)
    end
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

  def index_with_test_result(test)
    test_result = TestResult.make device: device
    test_result.core_fields = JSON.parse((test[:test] || {}).to_json)

    if test[:encounter]
      encounter = Encounter.make_unsaved institution: test_result.institution
      encounter.core_fields.merge! JSON.parse(test[:encounter].to_json)
      test_result.encounter = encounter
    end

    if test[:patient]
      patient = Patient.make_unsaved institution: test_result.institution
      patient.core_fields.merge! JSON.parse(test[:patient].to_json)
      test_result.patient = patient
    end

    if (reported_time = test_result.core_fields["reported_time"])
      test_result.created_at = Time.parse(reported_time)
    end

    TestResultIndexer.new(test_result).index(refresh = true)
  end

end
