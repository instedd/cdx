class LaboratorySamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = LaboratorySample.all

    @samples = @samples.where("uuid LIKE concat('%', ?, '%')", params[:uuid]) unless params[:uuid].blank?

    # paginate samples
    @samples = perform_pagination(@samples)
  end

  def new
    @sample = LaboratorySample.new
  end

  def create

    @sample = LaboratorySample.new({:uuid => uuid_param})

    if @sample.save
      next_url = laboratory_samples_path(@sample)
      redirect_to next_url, notice: 'Sample was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def uuid_param
    params.require(:uuid)
  end
end
