json.array!(@facilities) do |device|
  json.extract! device, :id, :name, :work_group_id
  json.url device_url(device, format: :json)
end
