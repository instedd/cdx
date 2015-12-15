shared_context "elasticsearch", elasticsearch: true do

  before(:each) do
    Cdx::Api.client.indices.delete index: Cdx::Api.index_name, ignore: 404
    
    Cdx::Api.client.indices.delete index: Cdx::Api.index_name, type: '.percolator', ignore: 404
   
                              
    Cdx::Api.client.indices.delete_template name: "cdx_tests_template_test*", ignore: 404
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_test"
    Cdx::Api.client.indices.create index: Cdx::Api.index_name,
                                   body: {
                                    settings: {
                                      index: {
                                        number_of_shards: 1,
                                        number_of_replicas: 0
                                      }
                                    }
                                  }
  end

  def index(body)
    Cdx::Api.client.index index: Cdx::Api.index_name, type: "test", body: body, refresh: true
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
      type: "test",
    )
    results["hits"]["hits"]
  end

  def all_elasticsearch_encounters
    results = fresh_client.search(
      index: Cdx::Api.index_name,
      from: 0,
      size: 1000,
      type: "encounter",
    )
    results["hits"]["hits"]
  end
end
