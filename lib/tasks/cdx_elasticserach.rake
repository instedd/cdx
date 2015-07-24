namespace :cdx_elasticserach do
  desc "Initialize the cdx elasticsearch index template"
  task initialize_template: :environment do
    Cdx::Api::Elasticsearch::MappingTemplate.new.initialize_template "cdx_tests_template_#{Rails.env}"
    begin
      Cdx::Api.client.indices.create index: Cdx::Api.index_name
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => ex
      raise unless ex.message =~ /IndexAlreadyExistsException/
    end
  end
end
