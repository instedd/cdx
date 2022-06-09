json.array!(@samples) do |sample|
  json.uuid sample.uuid
  json.batch_number sample.batch_number

  json.value sample.uuid
  json.label "#{sample.uuid} (#{sample.batch_number})"
end
