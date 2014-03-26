defmodule Cdp.Report do
  use Ecto.Model

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
    report = Cdp.Report.new [
      work_group_id: device.work_group_id,
      device_id: device.id,
      data: data,
      created_at: now,
      updated_at: now,
    ]
    Cdp.Repo.create(report)
  end
end
