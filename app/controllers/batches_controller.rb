class BatchesController < ApplicationController

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_BATCH)

    @batches = Batch.where(institution: @navigation_context.institution)
    @batches = check_access(@batches, READ_BATCH).order('created_at DESC')

    @batches = @batches.within(@navigation_context.entity, @navigation_context.exclude_subsites)

    @batches = @batches.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @batches = @batches.where("batch_number LIKE concat('%', ?, '%')", params[:batch_number]) unless params[:batch_number].blank?
    @batches = @batches.joins(samples: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @batches = @batches.where("date_produced >= ?", params[:date_produced_from].to_time) unless params[:date_produced_from].blank?
    @batches = @batches.where("date_produced <= ?", params[:date_produced_to].to_time) unless params[:date_produced_to].blank?

    #paginate batches
    @batches = perform_pagination(@batches)
  end

  def new
    @institution = @navigation_context.institution

    batch = Batch.new({
      institution: @navigation_context.institution,
      site: @navigation_context.site
    })

    @batch_form = BatchForm.for(batch)
    prepare_for_institution_and_authorize(@batch_form, CREATE_INSTITUTION_BATCH)

    @can_edit_sample_quantity = true
    @can_update = true
  end

  def create
    institution = @navigation_context.institution
    return unless authorize_resource(institution, CREATE_INSTITUTION_BATCH)

    batch = Batch.new(batch_params.merge({
      institution: institution,
      site: @navigation_context.site
    }))

    @batch_form = BatchForm.for(batch)
    @batch_form.samples_quantity = batch_samples_quantity_params

    if @batch_form.create
      redirect_to batches_path, notice: 'Batch was successfully created.'
    else
      @can_update = true
      @can_edit_sample_quantity = true
      render action: 'new'
    end
  end

  def show
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.for(batch)
    return unless authorize_resource(batch, READ_BATCH)

    @can_edit_sample_quantity = false
    @can_delete = false
    @can_update = false

    render action: 'edit'
  end

  def edit
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.for(batch)
    return unless authorize_resource(batch, UPDATE_BATCH)

    @can_edit_sample_quantity = false
    @can_delete = has_access?(batch, DELETE_BATCH)
    @can_update = true
  end

  def update
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.for(batch)
    return unless authorize_resource(batch, UPDATE_BATCH)
    if @batch_form.update(batch_params, remove_samples_params)
      redirect_to batches_path, notice: 'Batch was successfully updated.'
    else
      @can_update = true
      render action: 'edit'
    end
  end

  def destroy
    @batch = Batch.find(params[:id])
    return unless authorize_resource(@batch, DELETE_BATCH)

    @batch.destroy

    redirect_to batches_path, notice: 'Batch was successfully deleted.'
  end

  ## NO  CRUD METHODS
  def autocomplete
    batches = Batch
      .where(institution: @navigation_context.institution)
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .autocomplete(params[:query])
      .limit(10)

    @batches = check_access(batches, READ_BATCH).pluck(:uuid, :batch_number)
  end

  def existing_batch_number
    uuids = Batch.where(institution: @navigation_context.institution, batch_number: params[:batch_number]).pluck(:uuid)
    render json: { status: :ok, message: uuids }
  end

  def edit_or_show
    batch = Batch.find(params[:id])

    if has_access?(batch, UPDATE_BATCH)
      redirect_to edit_batch_path(batch)
    else
      redirect_to batch_path(batch)
    end
  end

  def bulk_destroy
    batch_ids = params[:batch_ids]

    if batch_ids.blank?
      redirect_to batches_path, notice: 'Select at least one batch to destroy.'
      return
    end

    batches = Batch.where(id: batch_ids)
    return unless authorize_resources(batches, DELETE_BATCH)

    batches.destroy_all

    redirect_to batches_path, notice: 'Batches were successfully deleted.'
  end

  def add_sample
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.for(batch)
    return unless authorize_resource(batch, UPDATE_BATCH)

    @batch_form.add_sample

    redirect_to edit_batch_path(@batch_form), notice: 'New sample was added successfully.'
  end

  private

  def batch_params
    params.require(:batch).permit(
      :batch_number,
      :date_produced,
      :lab_technician,
      :specimen_role,
      :isolate_name,
      :inactivation_method,
      :volume,
      :virus_lineage,
      :reference_gene,
      :target_organism_taxonomy_id,
      :pango_lineage,
      :who_label
    )
  end

  def batch_samples_quantity_params
    params.require(:batch).permit(:samples_quantity)[:samples_quantity].to_i
  end

  def remove_samples_params
    (params[:destroy_sample_ids] || []).map(&:to_i)
  end
end
