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

  def create(device_id, data) do
    device = Cdp.Repo.get Cdp.Device, device_id
    now = Cdp.DateTime.now

    # Create in DB
    report = Cdp.Report.new [
      work_group_id: device.work_group_id,
      device_id: device.id,
      data: data,
      created_at: now,
      updated_at: now,
    ]
    Cdp.Repo.create(report)

    # Create in ElasticSearch
    {:ok, data_as_json} = JSON.decode data
    data_as_json = HashDict.put data_as_json, :type, "report"

    settings = Tirexs.ElasticSearch.Config.new()

    Tirexs.Bulk.store [index: "work_group_#{device.work_group_id}", refresh: true], settings do
      create data_as_json
    end
  end
end
