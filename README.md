# Cdx::Api::Elasticsearch

[![Build Status](https://travis-ci.org/instedd/cdx-api-elasticsearch.svg)](https://travis-ci.org/instedd/cdx-api-elasticsearch)

Provides an implementation of the [CDX query API](http://dxapi.org/#/query-events) based on an ElasticSearch backend.

## Installation

Add this line to your application's Gemfile:

    gem 'cdx-api-elasticsearch', :git => 'https://github.com/instedd/cdx-api-elasticsearch'

And then execute:

    $ bundle

Or install it yourself as:

    $ git clone https://github.com/instedd/cdx-api-elasticsearch
    $ cd cdx-api-elasticsearch
    $ gem build cdx-api-elasticsearch.gemspec
    $ gem install cdx-api-elasticsearch-0.0.1.gem

### Configuration

Initialize the gem with a default configuration. In Rails, you can set up a `config/initializers/cdx_api_elasticsearch.rb` file with the following contents:

```ruby
require "cdx/api/elasticsearch"

Cdx::Api.setup do |config|
  config.document_format = MyDocumentFormat.new # Change document format to use a custom class
  config.index_name_pattern = "tests_*"         # Required, indices to query in the ES instance
  config.log = true                             # Whether to enable logging for all queries
  config.elasticsearch_url = 'localhost:9200'   # URL to the ES instance
end
```

### Mapping

This gem assumes that all tests are stored in a canonical ElasticSearch index (or indices) with a mapping based on the standard core fields definition specified in [CDX API](http://dxapi.org/#/event-resource), and encoded in the [API fields definition](config/cdx_api_fields.yml).

This mapping can be automatically generated from the specification invoking `Cdx::Api::Service.initialize_default_template(template_name)`.

If your data is not stored using that same schema, you will need to provide a way of mapping the fields, filters and aggregations that do not match with the canonical mapping to your implementation. The simplest way to do this is to set up a [custom document format](lib/cdx/api/elasticsearch/custom_document_format.rb) with the mappings from the field names in the spec to your ES instance.

Alternatively, you can provide your own document format implementation, as long as it responds to two methods:

* `indexed_field_name(cdp_field_name)` Based on a canonical field name, provide the field name in your ES instance; this method is used for building the filters and aggregations in ES based on the query received.
* `translate_test(test)` Given an test or the result of an aggregation to be returned to the client, translate its keys to the ones expected by a CDX API consumer.

## Querying

To effectively run a CDX query, simply initialize a new instance of [`Cdx::Api::Elasticsearch::Query`](lib/cdx/api/elasticsearch/query.rb) with a hash of the parameters that specify the filters and aggregations, and invoke `execute` on it. Wrapped in a Rails controller, you would end up with something like:

```ruby
class CdxApiController < ApplicationController
  def tests
    render json: Cdx::Api::Elasticsearch::Query.new(params).execute
  end
end
```

### Authorisation

The `Query` class has a `process_conditions` method where it generates the filters to be executed on ES. This method can be overridden to concatenate any filters required by custom authorisation restrictions imposed by your application. Simply override the class and add your own restrictions:

```ruby
class MyCdxQuery < Cdx::Api::Elasticsearch::Query

  def initialize(params, context)
    super(params)
    @context = context
  end

  def process_conditions(params, conditions=[])
    super.concat(my_custom_filters_for(@context))
  end
```

### Multi-query

CDX supports batching queries to the backend for improved performance (though the current implementation is a naive one). A [MultiQuery](lib/cdx/api/elasticsearch/multi_query.rb) object can be initialised with an array of parameter hashes (one of each query) or an array of `Query`s. The `execute` method will then return an array with the responses.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
