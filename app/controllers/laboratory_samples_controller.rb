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

    @sample = LaboratorySample.new(sample_params.merge({
      uuid: uuid,
      institution: @navigation_context.institution
    }))

    if @sample.save
      session.delete(:creating_sample_uuid)
      redirect_to edit_laboratory_sample_path(@sample), notice: 'Sample was successfully created.'
    else
      render action: 'new'
    end
  end

  def print
    @sample = LaboratorySample.find(params[:id])

    @show_print_action = false

    render pdf: "cdx_sample_#{@sample.uuid}",
      template: 'laboratory_samples/barcode.pdf',
      layout: 'layouts/pdf.html',
      locals: { :sample => @sample },
      margin: { top: 2, bottom: 0, left: 0, right: 0 },
      page_width: '4in',
      page_height: '1.5in',
      show_as_html: params.key?('debug')
  end

  def bulk_print
    @samples = LaboratorySample.where(id: params[:sample_ids])

    if @samples.blank?
      redirect_to laboratory_samples_path, notice: 'Select at least one sample to print.'
      return
    end

    sample_strings = @samples.map do |sample|
      render_to_string template: 'laboratory_samples/barcode.pdf',
        layout: 'layouts/pdf.html',
        locals: {:sample => sample}
    end

    options = {
      margin: { top: 2, bottom: 0, left: 0, right: 0 },
      page_width: '4in',
      page_height: '1.5in'
    }

    begin
      pdf_file = MultipagePdfRenderer.combine(sample_strings, options)
      pdf_filename = "cdx_samples_#{@samples.size}_#{DateTime.now.strftime('%Y%m%d-%H%M')}.pdf"

      send_data pdf_file, type: 'application/pdf', filename: pdf_filename
    rescue
      redirect_to laboratory_samples_path, notice: 'There was an error creating the print file.'
    end
  end

  def edit
    @sample = LaboratorySample.find(params[:id])

    @show_barcode_preview = true
    @show_print_action = true

    # TODO: Implement user authorized to delete
    @can_delete = true
  end

  def update
    @sample = LaboratorySample.find(params[:id])
    # TODO:
    # return unless authorize_resource(patient, UPDATE_PATIENT)
    params = sample_params
    params[:is_quality_control] = params[:is_quality_control] == '1'

    if @sample.update(params)
      redirect_to edit_batch_path(@sample.batch), notice: 'Sample was successfully updated.'
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

  def bulk_destroy
    LaboratorySample.where(id: params[:sample_ids]).destroy_all

    redirect_to laboratory_samples_path, notice: 'Samples were successfully deleted.'
  end

  private

  def sample_params
    params.require(:laboratory_sample).permit(:is_quality_control)
  end
end
