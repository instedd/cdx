shared_context "elasticsearch", elasticsearch: true do

  before(:each) do
    Cdx::Api.client.indices.delete index: Cdx::Api.index_name rescue nil
    Cdx::Api.client.indices.delete_template(name: "cdx_tests_template_test*") rescue nil
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_test"
    Cdx::Api.client.indices.create index: Cdx::Api.index_name
  end

  def refresh_index
    fresh_client
  end

  def fresh_client
    client = Cdx::Api.client
    client.indices.refresh index: Cdx::Api.index_name
    client
  end

  def all_elasticsearch_tests
    results = fresh_client.search(
      index: Cdx::Api.index_name,
      from: 0,
      size: 1000,
    )
    results["hits"]["hits"]
  end
end
