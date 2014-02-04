json.array!(@subscribers) do |subscriber|
  json.extract! subscriber, :id, :name, :work_group_id
  json.url subscriber_url(subscriber, format: :json)
end
