json.array!(@work_groups) do |work_group|
  json.extract! work_group, :id, :name, :user_id
  json.url work_group_url(work_group, format: :json)
end
