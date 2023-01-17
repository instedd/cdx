json.array!(@samples) do |sample|
  json.uuid         sample.uuid
  json.batch_number sample.batch_number
  json.concentration sample.concentration
end
