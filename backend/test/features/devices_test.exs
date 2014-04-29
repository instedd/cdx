defmodule DevicesTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    institution = Repo.create Institution.new(name: "baz")
    laboratory = Repo.create Laboratory.new(institution_id: institution.id, name: "bar")
    device = Repo.create Device.new(institution_id: institution.id, secret_key: "foo")
    Repo.create DevicesLaboratories.new(laboratory_id: laboratory.id, device_id: device.id)
    data = JSON.encode! [result: "positive"]
    {:ok, institution: institution, device: device, data: data}
  end

  test "create test_result in postgres", meta do
    conn = post("/devices/foo", meta[:data])
    assert conn.status == 200

    [test_result] = Repo.all TestResult
    assert test_result.device_id == meta[:device].id
    assert test_result.raw_data != meta[:data]
    test_result = TestResult.decrypt(test_result)
    assert test_result.raw_data == meta[:data]
  end

  test "create test_result in elasticsearch", meta do
    post("/devices/foo", meta[:data])

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
    post("/devices/foo", data)

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

  # test "enqueues in RabbitMQ", meta do
  #   amqp_config = Dynamo.config[:rabbit_amqp]

  #   post("/devices/foo", meta[:data])

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

  teardown(meta) do
    Enum.each [Institution, Laboratory, Device, TestResult], &Repo.delete_all/1
    delete_index meta[:institution], Tirexs.ElasticSearch.Config.new()
  end

  def delete_index(institution, settings) do
    Tirexs.ElasticSearch.delete Institution.elasticsearch_index_name(institution.id), settings
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
