shared_context "elasticsearch", elasticsearch: true do

  before(:each) do
    Cdx::Api.client.indices.delete index: "#{Cdx::Api.index_prefix}_*" rescue nil
    ElasticsearchMappingTemplate.delete_templates!
    ElasticsearchMappingTemplate.create_default!
  end

  def refresh_indices index_name=nil
    Cdx::Api.client.indices.refresh index: index_name
  end

  def fresh_client_for index_name
    client = Cdx::Api.client
    client.indices.refresh index: index_name
    client
  end

  def all_elasticsearch_events_for(institution)
    client = fresh_client_for institution.elasticsearch_index_name
    client.search(index: institution.elasticsearch_index_name, from: 0, size: 1000)["hits"]["hits"]
  end

end
