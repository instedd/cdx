json.array!(@batches) do |(uuid, batch_number, samples)|
  json.value uuid
  json.label batch_number
  json.samples []
end
