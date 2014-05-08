defmodule ReportingTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  test "create test_result in postgres", context do
    conn = post("/api/devices/foo/results", context[:data])
    assert conn.status == 200

    [test_result] = Repo.all TestResult
    assert test_result.device_id == context[:device].id
    assert test_result.raw_data != context[:data]
    test_result = TestResult.decrypt(test_result)
    assert test_result.raw_data == context[:data]
  end

  test "create test_result in elasticsearch", context do
    post("/api/devices/foo/results", context[:data])

    search = Tirexs.Search.search [index: Institution.elasticsearch_index_name(context[:institution].id)] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["result"] == "positive"
    assert result["_source"]["created_at"] != nil
    assert result["_source"]["device_uuid"] == "foo"
  end

  test "doesn't store sensitive data in elasticsearch", context do
    data = "{\"result\": \"positive\", \"patient_id\": 1234}"
    post("/api/devices/foo/results", data)

    search = Tirexs.Search.search [index: Institution.elasticsearch_index_name(context[:institution].id)] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["result"] == "positive"
    assert result["_source"]["created_at"] != nil
    assert result["_source"]["patient_id"] == nil
  end

  test "store the location id when the device is registered in only one laboratory", context do
    post("/api/devices/foo/results", context[:data])

    search = Tirexs.Search.search [index: Institution.elasticsearch_index_name(context[:institution].id)] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == context[:location1].id
    assert result["_source"]["laboratory_id"] == context[:laboratory1].id
    assert Enum.sort(result["_source"]["parent_locations"]) == Enum.sort([context[:location1].id, context[:parent_location].id, context[:root_location].id])
  end

  test "store the parent location id when the device is registered more than one laboratory", context do
    Repo.insert DevicesLaboratories.new(laboratory_id: context[:laboratory2].id, device_id: context[:device].id)
    Repo.insert DevicesLaboratories.new(laboratory_id: context[:laboratory3].id, device_id: context[:device].id)

    post("/api/devices/foo/results", context[:data])

    search = Tirexs.Search.search [index: Institution.elasticsearch_index_name(context[:institution].id)] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == context[:root_location].id
    assert result["_source"]["laboratory_id"] == nil
    assert Enum.sort(result["_source"]["parent_locations"]) == Enum.sort([context[:root_location].id])
  end


  test "store the parent location id when the device is registered more than one laboratory with another tree order", context do
    Repo.insert DevicesLaboratories.new(laboratory_id: context[:laboratory3].id, device_id: context[:device].id)
    Repo.insert DevicesLaboratories.new(laboratory_id: context[:laboratory2].id, device_id: context[:device].id)

    post("/api/devices/foo/results", context[:data])

    search = Tirexs.Search.search [index: Institution.elasticsearch_index_name(context[:institution].id)] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == context[:root_location].id
    assert result["_source"]["laboratory_id"] == nil
    assert Enum.sort(result["_source"]["parent_locations"]) == Enum.sort([context[:root_location].id])
  end

  test "store nil if no location was found", context do
    Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar")

    post("/api/devices/bar/results", context[:data])

    search = Tirexs.Search.search [index: Institution.elasticsearch_index_name(context[:institution].id)] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == nil
    assert result["_source"]["laboratory_id"] == nil
    assert result["_source"]["parent_locations"] == []
  end
end
