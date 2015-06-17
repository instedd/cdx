namespace :cdx_elasticserach do
  desc "Initialize the cdx elasticsearch index template"
  task initialize_template: :environment do
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_#{environment}"
  end
end
