json.array!(@subscribers) do |subscriber|
  json.extract! subscriber, :id, :name, :institution_id
  json.url subscriber_url(subscriber, format: :json)
end
