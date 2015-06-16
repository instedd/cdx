shared_context "elasticsearch", elasticsearch: true do

  before(:each) do
    Cdx::Api.client.indices.delete index: "#{Cdx::Api.index_prefix}_*" rescue nil
    Cdx::Api.client.indices.delete_template(name: "cdx_tests_template_test*") rescue nil
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_test"
  end

  def refresh_indices index_name=nil
    Cdx::Api.client.indices.refresh index: index_name
  end

  def fresh_client_for index_name
    client = Cdx::Api.client
    client.indices.refresh index: index_name
    client
  end

  def all_elasticsearch_tests_for(institution)
    client = fresh_client_for institution.elasticsearch_index_name
    client.search(index: institution.elasticsearch_index_name, from: 0, size: 1000)["hits"]["hits"]
  end

end
