namespace :cdx_elasticserach do
  desc "Initialize the cdx elasticsearch index template"
  task initialize_template: :environment do
    ElasticsearchMappingTemplate.new.load
  end
end
