namespace :cdx_elasticsearch do
  desc "Initialize the cdx elasticsearch index template"
  task setup: :environment do
    Cdx::Api.config.log = false
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_#{Rails.env}"
    Cdx::Api.client.indices.delete index: Cdx::Api.index_name, ignore: 404
    Cdx::Api.client.indices.create index: Cdx::Api.index_name
  end

  desc "Re-Index all the test results into elasticsearch"
  task reindex: :setup do
    total_count = TestResult.count
    index = 0
    TestResult.includes({:device => [:device_model, :institution]}, :sample, :patient).find_each do |test_result|
      index += 1
      print "\rIndexing #{index} of #{total_count}"
      TestResultIndexer.new(test_result).index
    end
    puts "\rDone#{' ' * 50}"
  end
end
