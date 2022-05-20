json.array!(@batches) do |(uuid, batch_number)|
  json.value uuid
  json.label batch_number
end
