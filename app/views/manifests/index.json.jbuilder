json.array!(@manifests) do |manifest|
  json.extract! manifest, :id, :version, :models
  json.url manifest_url(manifest, format: :json)
end
