class LaboratorySamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = LaboratorySample.all

    @samples = @samples.where("uuid LIKE concat('%', ?, '%')", params[:uuid]) unless params[:uuid].blank?

    # paginate samples
    @samples = perform_pagination(@samples)
  end
end
