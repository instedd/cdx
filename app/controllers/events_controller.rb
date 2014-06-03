class EventsController < ApplicationController
  add_breadcrumb 'Results', :events_path

  def index
    @combo_laboratories = authorize_resource(Laboratory, READ_LABORATORY)

    query = {}
    query["laboratory"] = params["laboratory"] if params["laboratory"].present?
    query["condition"] = params["condition"] if params["condition"].present?
    url = "#{Settings.backend}/api/events?#{query.to_query}"

    @events = JSON.parse RestClient.get(url)
    @institutions = indexed_model @events, Institution, "institution_id"
    @laboratories = indexed_model @events, Laboratory, "laboratory_id"
    @devices = indexed_model @events, Device, "device_uuid", "secret_key"
  end

  private

  def indexed_model(events, model, es_field, db_field = "id")
    ids = @events.map { |event| event[es_field] }
    model.where(db_field => ids).index_by { |model| model[db_field] }
  end
end
