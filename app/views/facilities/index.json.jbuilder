json.array!(@facilities) do |facility|
  json.extract! facility, :id, :name, :work_group_id, :index_name
  json.url facility_url(facility, format: :json)
end
