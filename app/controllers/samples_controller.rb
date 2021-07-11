class SamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = Sample.all.order('created_at DESC')
    @samples = @samples.where("uuid LIKE concat('%', ?, '%')", params[:uuid]) unless params[:uuid].blank?
    # paginate samples
    @samples = perform_pagination(@samples)
  end

  # def new
  #   @sample = LaboratorySample.new
  #   session[:creating_sample_uuid] = @sample.uuid
  #   @show_barcode_preview = false
  # end

  # def create
  #   uuid = session[:creating_sample_uuid]

  #   if uuid.blank?
  #     redirect_to new_laboratory_sample_path, notice: 'There was an error creating the sample'
  #     return
  #   end

  #   @sample = LaboratorySample.new(sample_params.merge({
  #     uuid: uuid,
  #     institution: @navigation_context.institution
  #   }))

  #   if @sample.save
  #     session.delete(:creating_sample_uuid)
  #     redirect_to samples_path, notice: 'Sample was successfully created.'
  #   else
  #     render action: 'new'
  #   end
  # end

  def print
    @sample = Sample.find(params[:id])

    @show_print_action = false

    render pdf: "cdx_sample_#{@sample.uuid}",
      template: 'samples/barcode.pdf',
      layout: 'layouts/pdf.html',
      locals: { :sample => @sample },
      margin: { top: 2, bottom: 0, left: 0, right: 0 },
      page_width: '4in',
      page_height: '1.5in',
      show_as_html: params.key?('debug')
  end

  def bulk_print
    @samples = Sample.where(id: params[:sample_ids])

    if @samples.blank?
      redirect_to samples_path, notice: 'Select at least one sample to print.'
      return
    end

    sample_strings = @samples.map do |sample|
      render_to_string template: 'samples/barcode.pdf',
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
      redirect_to samples_path, notice: 'There was an error creating the print file.'
    end
  end

  def edit
    @sample = Sample.find(params[:id])
    # @sample.test_qc_result = TestQcResult.new if @sample.test_qc_result.nil?

    @view_helper = {
      production_date_placeholder: date_format[:placeholder],
      back_path: conditional_root_path(@sample)
    }

    @show_barcode_preview = true
    @show_print_action = true

    # TODO: Implement user authorized to delete
    @can_delete = true
  end

  def update
    @sample = Sample.find(params[:id])
    # TODO:
    # return unless authorize_resource(patient, UPDATE_PATIENT)

    if @sample.update(sample_params)
      redirect_to conditional_root_path(@sample), notice: 'Sample was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @sample = Sample.find(params[:id])
    # TODO:
    # return unless authorize_resource(@patient, DELETE_PATIENT)

    @sample.destroy

    redirect_to samples_path, notice: 'Sample was successfully deleted.'
  end

  def bulk_destroy
    Sample.where(id: params[:sample_ids]).destroy_all

    redirect_to samples_path, notice: 'Samples were successfully deleted.'
  end

  private

  def sample_params
    sample_params = params.require(:sample).permit(
      :isolate_name,
      :production_date,
      :inactivation_method,
      :volume,
      :lab_technician,
      :is_quality_control,
      assays_attributes: [ :id, :_destroy ],
      new_assays: [],
      notes_attributes: [:id, :description, :updated_at, :user_id, :_destroy],
      new_notes: []
    )

    # quality control as boolean
    sample_params[:is_quality_control] = sample_params[:is_quality_control] == '1'

    # adding author to new notes
    new_notes_with_author = (sample_params[:new_notes] || []).map do |note_description|
      { user: current_user, description: note_description }
    end
    sample_params[:new_notes] = new_notes_with_author

    sample_params
  end

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def conditional_root_path(sample)
    if sample.batch.nil?
      sample_path(sample)
    else
      edit_batch_path(sample.batch)
    end
  end
end
