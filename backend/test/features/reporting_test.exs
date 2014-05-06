defmodule ReportingTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  test "create test_result in postgres", meta do
    conn = post("/api/devices/foo/results", meta[:data])
    assert conn.status == 200

    [test_result] = Repo.all TestResult
    assert test_result.device_id == meta[:device].id
    assert test_result.raw_data != meta[:data]
    test_result = TestResult.decrypt(test_result)
    assert test_result.raw_data == meta[:data]
  end

  test "create test_result in elasticsearch", meta do
    post("/api/devices/foo/results", meta[:data])

    search = Tirexs.Search.search [index: meta[:index_name]] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["result"] == "positive"
    assert result["_source"]["created_at"] != nil
  end

  test "doesn't store sensitive data in elasticsearch", meta do
    data = "{\"result\": \"positive\", \"patient_id\": 1234}"
    post("/api/devices/foo/results", data)

    search = Tirexs.Search.search [index: meta[:index_name]] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["result"] == "positive"
    assert result["_source"]["created_at"] != nil
    assert result["_source"]["patient_id"] == nil
  end

  test "store the location id when the device is registered in only one laboratory", meta do
    post("/api/devices/foo/results", meta[:data])

    search = Tirexs.Search.search [index: meta[:index_name]] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == meta[:location1].id
    assert result["_source"]["laboratory_id"] == meta[:laboratory1].id
    assert Enum.sort(result["_source"]["parent_locations"]) == Enum.sort([meta[:location1].id, meta[:parent_location].id, meta[:root_location].id])
  end

  test "store the parent location id when the device is registered more than one laboratory", meta do
    Repo.create DevicesLaboratories.new(laboratory_id: meta[:laboratory2].id, device_id: meta[:device].id)
    Repo.create DevicesLaboratories.new(laboratory_id: meta[:laboratory3].id, device_id: meta[:device].id)

    post("/api/devices/foo/results", meta[:data])

    search = Tirexs.Search.search [index: meta[:index_name]] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == meta[:root_location].id
    assert result["_source"]["laboratory_id"] == nil
    assert Enum.sort(result["_source"]["parent_locations"]) == Enum.sort([meta[:root_location].id])
  end


  test "store the parent location id when the device is registered more than one laboratory with another tree order", meta do
    Repo.create DevicesLaboratories.new(laboratory_id: meta[:laboratory3].id, device_id: meta[:device].id)
    Repo.create DevicesLaboratories.new(laboratory_id: meta[:laboratory2].id, device_id: meta[:device].id)

    post("/api/devices/foo/results", meta[:data])

    search = Tirexs.Search.search [index: meta[:index_name]] do
      query do
        match_all
      end
    end
    [result] = Tirexs.Query.create_resource(search).hits
    assert result["_source"]["location_id"] == meta[:root_location].id
    assert result["_source"]["laboratory_id"] == nil
    assert Enum.sort(result["_source"]["parent_locations"]) == Enum.sort([meta[:root_location].id])
  end

  test "store nil if no location was found", meta do
    Repo.create Device.new(institution_id: meta[:institution].id, secret_key: "bar")

    post("/api/devices/bar/results", meta[:data])

    search = Tirexs.Search.search [index: meta[:index_name]] do
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
