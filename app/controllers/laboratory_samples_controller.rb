class LaboratorySamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = LaboratorySample.all.order('created_at DESC')

    @samples = @samples.where("uuid LIKE concat('%', ?, '%')", params[:uuid]) unless params[:uuid].blank?

    # paginate samples
    @samples = perform_pagination(@samples)
  end

  def new
    @sample = LaboratorySample.new
    session[:creating_sample_uuid] = @sample.uuid
  end

  def create
    uuid = session[:creating_sample_uuid]

    if uuid.blank?
      redirect_to new_laboratory_sample_path, notice: 'There was an error creating the sample'
      return
    end

    @sample = LaboratorySample.new(sample_params.merge(uuid: uuid))

    if @sample.save
      session.delete(:creating_sample_uuid)

      next_url = laboratory_samples_path(@sample)
      redirect_to next_url, notice: 'Sample was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def sample_params
    params.require(:laboratory_sample).permit(:sample_type)
  end
end
