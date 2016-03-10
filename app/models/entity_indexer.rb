class EntityIndexer

  include EntityIndexableFields

  subclass_responsibility :type, :document_id, :fields_to_index

  def initialize(entity_name)
    @entity_name = entity_name
  end

  def index(refresh = false)
    fields = fields_to_index
    run_before_index_hooks(fields)
    options = {index: Cdx::Api.index_name, type: type, body: fields, id: document_id}
    options[:refresh] = true if refresh
    client.index(options)
    after_index(options)
  end

  def run_before_index_hooks(fields)
    Cdx::Fields[@entity_name].core_field_scopes.each do |scope|
      scope.fields.each do |field|
        field.before_index fields
      end
    end
  end

  def destroy
    client.delete(index: Cdx::Api.index_name, type: type, id: document_id)
  end

  def client
    Cdx::Api.client
  end

end
