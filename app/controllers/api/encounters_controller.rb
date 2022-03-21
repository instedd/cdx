class Api::EncountersController < ApiController
  wrap_parameters false

  def index
    body = Oj.load(request.body.read) || {}

    filters = params.permit!.to_h.merge(body)
    filters.delete(:format)
    filters.delete(:controller)
    filters.delete(:action)

    query = Encounter.query(filters, current_user)

    respond_to do |format|
      format.csv do
        @filename = "Encounters-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
        headers["Content-Type"] = "text/csv"
        headers["Content-disposition"] = "attachment; filename=#{@filename}"
        if query.grouped_by.empty?
          self.response_body = EntityCsvBuilder.new("encounter", query, @filename)
        else
          @csv_options = { col_sep: ',' }
          @csv_builder = CSVBuilder.new(
            query.execute[Cdx::Fields.encounter.result_name],
            column_names: query.grouped_by.concat(['count'])
          )
        end
      end
      format.json { render json: query.execute }
    end
  end

  def pii
    encounter = Encounter.find_by_uuid(params[:id])
    return unless authorize_resource(encounter, Policy::Actions::PII_ENCOUNTER)
    render json: { "uuid" => params[:id], "pii" => encounter.pii_data }
  end

  def schema
    schema = EncountersSchema.new params["locale"]
    respond_to do |format|
      format.json { render json: Oj.dump(schema.build) }
    end
  end
end
