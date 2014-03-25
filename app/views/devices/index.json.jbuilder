json.array!(@facilities) do |device|
  json.extract! device, :id, :name, :work_group_id, :index_name
  json.url device_url(device, format: :json)
end
