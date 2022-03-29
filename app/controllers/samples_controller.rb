class SamplesController < ApplicationController
  include Concerns::ViewHelper

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_SAMPLE)

    @samples = Sample.where(institution: @navigation_context.institution)
    @samples = check_access(@samples, READ_SAMPLE).order("created_at DESC")

    @samples = @samples.within(@navigation_context.entity, @navigation_context.exclude_subsites)

    @samples = @samples.joins(:sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @samples = @samples.joins("LEFT JOIN batches ON batches.id = samples.batch_id").where("batches.batch_number LIKE concat('%', ?, '%') OR samples.old_batch_number LIKE concat('%', ?, '%')", params[:batch_number], params[:batch_number]) unless params[:batch_number].blank?
    @samples = @samples.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @samples = @samples.where("specimen_role = ?", params[:specimen_role]) unless params[:specimen_role].blank?

    @institutions = Institution
      .where()
      .not(uuid: @navigation_context.institution.uuid)
      .order(name: :asc)
      .pluck(:uuid, :name)
      .map { |uuid, name| { value: uuid, label: name } }

    @samples = perform_pagination(@samples)
      .preload(:batch, :sample_identifiers)
  end

  def edit_or_show
    sample = Sample.find(params[:id])

    if has_access?(sample, UPDATE_SAMPLE)
      redirect_to edit_sample_path(sample)
    else
      redirect_to sample_path(sample)
    end
  end

  def show
    sample = Sample.find(params[:id])
    @sample_form = SampleForm.for(sample)
    return unless authorize_resource(sample, READ_SAMPLE)

    @view_helper = view_helper({ save_back_path: true })

    @show_barcode_preview = true
    @show_print_action = true

    @can_delete = false
    @can_update = false

    render action: "edit"
  end

  def new
    session[:creating_sample_uuid] = SampleIdentifier.new.uuid

    sample = Sample.new({
      institution: @navigation_context.institution,
      site: @navigation_context.site,
      sample_identifiers: [SampleIdentifier.new({ uuid: session[:creating_sample_uuid] })],
    })

    @sample_form = SampleForm.for(sample)
    prepare_for_institution_and_authorize(@sample_form, CREATE_INSTITUTION_SAMPLE)

    @view_helper = view_helper({ save_back_path: true })
    @show_barcode_preview = false
    @can_update = true
  end

  def create
    institution = @navigation_context.institution
    return unless authorize_resource(institution, CREATE_INSTITUTION_SAMPLE)

    uuid = session[:creating_sample_uuid]
    if uuid.blank?
      redirect_to new_sample_path, notice: "There was an error creating the sample"
      return
    end

    sample = Sample.new(sample_params.merge({
      institution: institution,
      site: @navigation_context.site,
      sample_identifiers: [SampleIdentifier.new({ uuid: uuid })],
    }))
    @sample_form = SampleForm.for(sample)

    if @sample_form.save
      session.delete(:creating_sample_uuid)
      redirect_to samples_path, notice: "Sample was successfully created."
    else
      @view_helper = view_helper
      @can_update = true
      render action: "new"
    end
  end

  def print
    @sample = Sample.find(params[:id])
    return unless authorize_resource(@sample, READ_SAMPLE)

    @show_print_action = false

    render pdf: "cdx_sample_#{@sample.uuid}",
      template: "samples/barcode.pdf",
      layout: "layouts/pdf.html",
      locals: { :sample => @sample },
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
      page_width: "1in",
      page_height: "1in",
      show_as_html: params.key?("debug")
  end

  def bulk_print
    sample_ids = params[:sample_ids]

    if sample_ids.blank?
      redirect_to samples_path, notice: "Select at least one sample to print."
      return
    end

    samples = Sample.where(id: params[:sample_ids])
    return unless authorize_resources(samples, READ_SAMPLE)

    sample_strings = samples.map do |sample|
      render_to_string template: "samples/barcode.pdf",
        layout: "layouts/pdf.html",
        locals: { :sample => sample }
    end

    options = {
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
      page_width: "1in",
      page_height: "1in",
    }

    begin
      pdf_file = MultipagePdfRenderer.combine(sample_strings, options)
      pdf_filename = "cdx_samples_#{samples.size}_#{DateTime.now.strftime("%Y%m%d-%H%M")}.pdf"

      send_data pdf_file, type: "application/pdf", filename: pdf_filename
    rescue
      redirect_to samples_path, notice: "There was an error creating the print file."
    end
  end

  def edit
    sample = Sample.find(params[:id])
    @sample_form = SampleForm.for(sample)
    return unless authorize_resource(sample, UPDATE_SAMPLE)

    @view_helper = view_helper({ save_back_path: true })

    @show_barcode_preview = true
    @show_print_action = true

    @can_delete = has_access?(sample, DELETE_SAMPLE)
    @can_update = true
  end

  def update
    sample = Sample.find(params[:id])
    @sample_form = SampleForm.for(sample)
    return unless authorize_resource(sample, UPDATE_SAMPLE)

    params = sample_params
    unless user_can_delete_notes(params["notes_attributes"] || [])
      redirect_to edit_sample_path(sample.id), notice: "Update failed: Notes can only be deleted by their authors"
      return
    end

    if @sample_form.update(sample_params)
      redirect_to back_path, notice: "Sample was successfully updated."
    else
      @view_helper = view_helper
      @can_update = true
      render action: "edit"
    end
  end

  def destroy
    @sample = Sample.find(params[:id])
    return unless authorize_resource(@sample, DELETE_SAMPLE)

    @sample.destroy

    redirect_to samples_path, notice: "Sample was successfully deleted."
  end

  def bulk_destroy
    sample_ids = params[:sample_ids]

    if sample_ids.blank?
      redirect_to samples_path, notice: "Select at least one sample to destroy."
      return
    end

    samples = Sample.where(id: sample_ids)
    return unless authorize_resources(samples, DELETE_SAMPLE)

    samples.destroy_all

    redirect_to samples_path, notice: "Samples were successfully deleted."
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
      assay_attachments_attributes: [:id, :loinc_code_id, :result, :assay_file_id, :_destroy],
      notes_attributes: [:id, :description, :updated_at, :user_id, :_destroy],
    )

    if sample_params[:notes_attributes].present?
      # adding author to new notes
      sample_params[:notes_attributes]
        .select { |key, note| note[:id].nil? } # select new notes
        .each { |key, note| note[:user] = current_user } # add current_user as author of the new note
    end

    sample_params
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
