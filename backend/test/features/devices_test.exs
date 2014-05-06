defmodule DevicesTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    institution = Repo.create Institution.new(name: "baz")
    root_location = Repo.create Location.new(name: "locr")
    parent_location = Repo.create Location.new(name: "locp", parent_id: root_location.id)
    location1 = Repo.create Location.new(name: "loc1", parent_id: parent_location.id)
    location2 = Repo.create Location.new(name: "loc2", parent_id: parent_location.id)
    location3 = Repo.create Location.new(name: "loc3", parent_id: root_location.id)
    laboratory1 = Repo.create Laboratory.new(institution_id: institution.id, name: "bar", location_id: location1.id)
    laboratory2 = Repo.create Laboratory.new(institution_id: institution.id, name: "bar", location_id: location2.id)
    laboratory3 = Repo.create Laboratory.new(institution_id: institution.id, name: "bar", location_id: location3.id)
    device = Repo.create Device.new(institution_id: institution.id, secret_key: "foo")
    Repo.create DevicesLaboratories.new(laboratory_id: laboratory1.id, device_id: device.id)
    data = JSON.encode! [result: "positive"]
    {:ok, institution: institution, device: device, data: data, root_location: root_location, parent_location: parent_location, location1: location1, location2: location2, laboratory1: laboratory1, laboratory2: laboratory2, laboratory3: laboratory3}
  end

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

  # test "enqueues in RabbitMQ", meta do
  #   amqp_config = Dynamo.config[:rabbit_amqp]

  #   post("/api/devices/foo/results", meta[:data])

  #   amqp = Exrabbit.Utils.connect
  #   channel = Exrabbit.Utils.channel amqp
  #   # Exrabbit.Utils.get_messages channel, amqp_config[:subscribers_queue]
  #   case Exrabbit.Utils.get_messages_ack channel, amqp_config[:subscribers_queue] do
  #       nil -> assert false, "No message received"
  #       [tag: tag, content: json_message] ->
  #           # IO.puts json_message
  #           {:ok, message } = JSON.decode json_message
  #           IO.inspect(message)
  #           assert message["test_result"] == meta[:data]
  #           assert message["subscriber"] == meta[:subscriber].id
  #           Exrabbit.Utils.ack channel, tag
  #   end
  # end

  teardown do
    Enum.each [Institution, Laboratory, Device, TestResult], &Repo.delete_all/1
    Tirexs.ElasticSearch.delete "#{Elasticsearch.index_prefix}*", Tirexs.ElasticSearch.Config.new()
  end

    # amqp_config = Dynamo.config[:rabbit_amqp]
    # amqp = Exrabbit.Utils.connect
    # channel = Exrabbit.Utils.channel amqp
    # Exrabbit.Utils.declare_queue channel, amqp_config[:subscribers_queue], true
    # case Exrabbit.Utils.get_messages_ack channel, amqp_config[:subscribers_queue] do
    #     nil -> IO.puts "No message deleted"
    #     [tag: tag, content: json_message] ->
    #         IO.puts json_message
    #         Exrabbit.Utils.ack channel, tag
    # end
end
