class EntityIndexUpdater

  include EntityIndexableFields

  attr_accessor :entity

  def initialize(entity)
    @entity = entity
  end

  def update
    response = client.search index: Cdx::Api.index_name,
      body: {
        query: {
          filtered: {
            filter: {
              terms: { "#{entity.entity_scope}.uuid" => entity.uuids }
            }
          }
        },
        fields: []
      }, size: 10000 # TODO: Page over results

    body = response["hits"]["hits"].map do |element|
      {
        update: {
          _type: element["_type"], _id: element["_id"], data: {
            doc: { entity.entity_scope => fields_to_update }
          }
        }
      }
    end

    client.bulk index: Cdx::Api.index_name, body: body unless body.blank?
  end

  def client
    Cdx::Api.client
  end

  def fields_to_update
    case entity
    when Sample then sample_fields(entity)
    when Encounter then encounter_fields(entity)
    when Patient then patient_fields(entity)
    else raise "Unsupported entity for update: #{entity}"
    end
  end

end
