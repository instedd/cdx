defmodule DevicesTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    work_group = Cdp.Repo.create Cdp.WorkGroup.new
    # subscriber = Cdp.Repo.create Cdp.Subscriber.new(work_group_id: work_group.id, auth_token: "foo", callback_url: "http://bar.baz")
    device = Cdp.Repo.create Cdp.Device.new(work_group_id: work_group.id, secret_key: "foo")
    data = "{\"result\": \"positive\"}"
    settings = Tirexs.ElasticSearch.Config.new()
    index_name = Cdp.WorkGroup.elasticsearch_index_name(work_group.id)
    # {:ok, work_group: work_group, device: device, data: data, settings: settings, index_name: index_name, subscriber: subscriber}
    {:ok, work_group: work_group, device: device, data: data, settings: settings, index_name: index_name}
  end

  test "create report in postgres", meta do
    conn = post("/devices/foo", meta[:data])
    assert conn.status == 200

    [report] = Cdp.Repo.all Cdp.Report
    assert report.work_group_id == meta[:work_group].id
    assert report.device_id == meta[:device].id
    assert report.data == meta[:data]
  end

  test "create report in elasticsearch", meta do
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

  # test "enqueues in RabbitMQ", meta do
  #   amqp_config = Cdp.Dynamo.config[:rabbit_amqp]

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
  #           assert message["report"] == meta[:data]
  #           assert message["subscriber"] == meta[:subscriber].id
  #           Exrabbit.Utils.ack channel, tag
  #   end
  # end

  teardown(meta) do
    Enum.each [Cdp.WorkGroup, Cdp.Device, Cdp.Report], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]

    # amqp_config = Cdp.Dynamo.config[:rabbit_amqp]
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
end
