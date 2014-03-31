defmodule Cdp.Report do
  use Ecto.Model
  import Tirexs.Bulk

  queryable "reports" do
    field :work_group_id, :integer
    field :device_id, :integer
    field :created_at, :datetime
    field :updated_at, :datetime
    field :data, :binary
  end

  def create_in_db(device, data) do
    now = Cdp.DateTime.now
    report = Cdp.Report.new [
      work_group_id: device.work_group_id,
      device_id: device.id,
      data: data,
      created_at: now,
      updated_at: now,
    ]
    Cdp.Repo.create(report)
  end

  def create_in_elasticsearch(device, data) do
    {:ok, data_as_json} = JSON.decode data
    data_as_json = Dict.put data_as_json, :type, "report"

    settings = Tirexs.ElasticSearch.Config.new()

    Tirexs.Bulk.store [index: Cdp.WorkGroup.elasticsearch_index_name(device.work_group_id), refresh: true], settings do
      create data_as_json
    end
  end

  # def enqueue_in_rabbit(device, data) do
  #   subscribers = Cdp.Subscriber.find_by_work_group_id(device.work_group_id)

  #   amqp_config = Cdp.Dynamo.config[:rabbit_amqp]
  #   amqp = Exrabbit.Utils.connect
  #   channel = Exrabbit.Utils.channel amqp
  #   Exrabbit.Utils.declare_exchange channel, amqp_config[:subscribers_exchange]
  #   Exrabbit.Utils.declare_queue channel, amqp_config[:subscribers_queue], true
  #   Exrabbit.Utils.bind_queue channel, amqp_config[:subscribers_queue], amqp_config[:subscribers_exchange]

  #   Enum.each subscribers, fn(s) ->
  #     IO.puts s.id
  #     {:ok, message} = JSON.encode([report: data, subscriber: s.id])
  #     Exrabbit.Utils.publish channel, amqp_config[:subscribers_exchange], "", message
  #   end
  # end

  def create_and_enqueue(device_key, data) do
    device = Cdp.Device.find_by_key(device_key)

    Cdp.Report.create_in_db(device, data)
    Cdp.Report.create_in_elasticsearch(device, data)
    # Cdp.Report.enqueue_in_rabbit(device, data)
  end
end
