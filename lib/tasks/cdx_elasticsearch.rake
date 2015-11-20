namespace :cdx_elasticsearch do
  desc "Initialize the cdx elasticsearch index template"
  task setup: :environment do
    Cdx::Api.config.log = false
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_#{Rails.env}"
    Cdx::Api.client.indices.delete index: Cdx::Api.index_name, ignore: 404
    Cdx::Api.client.indices.create index: Cdx::Api.index_name
  end

  desc "Re-Index all the test results and encounters into elasticsearch"
  task reindex: :setup do

    # Reindex tests
    total_count = TestResult.count
    TestResult.includes({:device => [:device_model, :institution]}, {:sample_identifier => :sample}, :patient).find_each.each_with_index do |test_result, index|
      print "\rIndexing test #{index} of #{total_count}"
      TestResultIndexer.new(test_result).index
    end

    # Reindex encounters
    total_count = Encounter.count
    Encounter.includes(:patient, :institution).find_each.each_with_index do |encounter, index|
      print "\rIndexing encounter #{index} of #{total_count}"
      EncounterIndexer.new(encounter).index
    end
    puts "\rDone#{' ' * 50}"
  end
end
