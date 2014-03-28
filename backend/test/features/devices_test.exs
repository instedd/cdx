defmodule DevicesTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    work_group = Cdp.Repo.create Cdp.WorkGroup.new
    device = Cdp.Repo.create Cdp.Device.new(work_group_id: work_group.id, secret_key: "foo")
    data = "{\"result\": \"positive\"}"
    settings = Tirexs.ElasticSearch.Config.new()
    index_name = Cdp.WorkGroup.elasticsearch_index_name(work_group.id)
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
  end

  test "enqueues in RabbitMQ", meta do
    amqp_config = Cdp.Dynamo.config[:rabbit_amqp]

    post("/devices/foo", meta[:data])

    amqp = Exrabbit.Utils.connect
    channel = Exrabbit.Utils.channel amqp
    Exrabbit.Utils.declare_queue channel, amqp_config[:subscribers_queue]
    Exrabbit.Utils.bind_queue channel, amqp_config[:subscribers_queue], amqp_config[:subscribers_exchange]
    Exrabbit.Utils.get_messages channel, amqp_config[:subscribers_queue]
    case Exrabbit.Utils.get_messages_ack channel, amqp_config[:subscribers_queue] do
        nil -> assert false
        [tag: tag, content: message] ->
            assert message == meta[:data]
            Exrabbit.Utils.ack channel, tag
    end
  end

  teardown(meta) do
    Enum.each [Cdp.WorkGroup, Cdp.Device, Cdp.Report], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]
  end
end
