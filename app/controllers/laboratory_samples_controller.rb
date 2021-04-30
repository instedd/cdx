class LaboratorySamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = LaboratorySample.all.order('created_at DESC')

    @samples = @samples.where("uuid LIKE concat('%', ?, '%')", params[:uuid]) unless params[:uuid].blank?
    @samples = @samples.where("sample_type = ?", params[:sample_type]) unless params[:sample_type].blank?

    # paginate samples
    @samples = perform_pagination(@samples)
  end

  def new
    @sample = LaboratorySample.new
    session[:creating_sample_uuid] = @sample.uuid
    @show_barcode_preview = false
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

  def print
    @sample = LaboratorySample.find(params[:id])
    @institution = @navigation_context.institution

    @show_print_action = false

    render pdf: "#{@sample.uuid}",
      template: 'laboratory_samples/barcode.pdf',
      layout: 'layouts/pdf.html',
      margin: { top: 5, bottom: 5, left: 5, right: 5 },
      page_height: 300,
      page_width: 80,
      disable_smart_shrinking: true,
      orientation: 'Landscape',
      show_as_html: params.key?('debug')
  end

  def edit
    @sample = LaboratorySample.find(params[:id])
    @institution = @navigation_context.institution

    @show_barcode_preview = true
    @show_print_action = true

    # TODO: Implement user authorized to delete
    @can_delete = true
  end

  def update
    @sample = LaboratorySample.find(params[:id])
    # TODO:
    # return unless authorize_resource(patient, UPDATE_PATIENT)

    if @sample.update(update_sample_params)
      redirect_to laboratory_samples_path, notice: 'Sample was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @sample = LaboratorySample.find(params[:id])
    # TODO:
    # return unless authorize_resource(@patient, DELETE_PATIENT)

    @sample.destroy

    redirect_to laboratory_samples_path, notice: 'Sample was successfully deleted.'
  end

  private

  def sample_params
    params.require(:laboratory_sample).permit(:sample_type)
  end

  def update_sample_params
    params.require(:laboratory_sample).permit(:sample_type)
  end
end
