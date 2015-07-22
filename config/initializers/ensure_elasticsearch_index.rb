begin
  Cdx::Api.client.indices.create index: Cdx::Api.index_name
rescue Elasticsearch::Transport::Transport::Errors::BadRequest => ex
  raise unless ex.message =~ /IndexAlreadyExistsException/
end
