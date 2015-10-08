json.array!(@laboratories) do |laboratory|
  json.extract! laboratory, :id
  json.url laboratory_url(laboratory, format: :json)
end
