class SamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = Sample.all.order('created_at DESC')
    @samples = @samples.joins(:sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @samples = @samples.joins(:batch).where("batches.batch_number LIKE concat('%', ?, '%')", params[:batch_number]) unless params[:batch_number].blank?
    @samples = @samples.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?

    # paginate samples
    @samples = perform_pagination(@samples)
  end

  def new
    session[:creating_sample_uuid] = SampleIdentifier.new.uuid

    sample = Sample.new({
      institution: @navigation_context.institution,
      sample_identifiers: [SampleIdentifier.new({uuid: session[:creating_sample_uuid]})],
      specimen_role: "Q - Control specimen"
    })

    @sample_form = SampleForm.for(sample)
    @view_helper = view_helper({save_back_path: true})
    @show_barcode_preview = false
  end

  def create
    uuid = session[:creating_sample_uuid]

    if uuid.blank?
      redirect_to new_sample_path, notice: 'There was an error creating the sample'
      return
    end

    sample = Sample.new(sample_params.merge({
      institution: @navigation_context.institution,
      sample_identifiers: [SampleIdentifier.new({uuid: uuid})]
    }))
    @sample_form = SampleForm.for(sample)

    if @sample_form.save
      session.delete(:creating_sample_uuid)
      redirect_to samples_path, notice: 'Sample was successfully created.'
    else
      @view_helper = view_helper
      render action: 'new'
    end
  end

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
    sample = Sample.find(params[:id])
    @sample_form = SampleForm.for(sample)

    @view_helper = view_helper({save_back_path: true})

    @show_barcode_preview = true
    @show_print_action = true

    # TODO: Implement user authorized to delete
    @can_delete = true
  end

  def update
    sample = Sample.find(params[:id])
    @sample_form = SampleForm.for(sample)

    # TODO:
    # return unless authorize_resource(patient, UPDATE_PATIENT)
    params = sample_params
    unless user_can_delete_notes(params["notes_attributes"] || [])
      redirect_to edit_sample_path(sample.id), notice: 'Update failed: Notes can only be deleted by their authors'
      return
    end

    if @sample_form.update(sample_params)
      redirect_to back_path, notice: 'Sample was successfully updated.'
    else
      @view_helper = view_helper
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
    sample_ids = params[:sample_ids]

    if sample_ids.blank?
      redirect_to samples_path, notice: 'Select at least one sample to destroy.'
      return
    end

    Sample.where(id: sample_ids).destroy_all

    redirect_to samples_path, notice: 'Samples were successfully deleted.'
  end

  private

  def sample_params
    sample_params = params.require(:sample).permit(
      :date_produced,
      :lab_technician,
      :specimen_role,
      :isolate_name,
      :inactivation_method,
      :volume,
      assay_attachments_attributes: [ :id,:loinc_code_id, :result, :_destroy ],
      new_assays: [],
      notes_attributes: [:id, :description, :updated_at, :user_id, :_destroy],
      new_notes: []
    )

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

  def view_helper(save_back_path = false)
    if save_back_path
      session[:back_path] = URI(request.referer || '').path
    end
    back_path = session[:back_path] || samples_path

    { date_produced_placeholder: date_format[:placeholder], back_path: back_path }
  end

  def back_path()
    session.delete(:back_path) || samples_path
  end

  def user_can_delete_notes(notes)
    notes = notes.values unless notes.empty?

    notes_id_to_destroy = notes
      .select { |note| note["_destroy"] == "1" }
      .map { |note| note["id"] }

    can_delete = Note
      .find(notes_id_to_destroy)
      .all? { |db_note| db_note.user_id == current_user.id }
  end
end
