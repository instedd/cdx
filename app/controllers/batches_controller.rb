class BatchesController < ApplicationController

  def index
    @batches = Batch.all.order('created_at DESC')

    @batches = @batches.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @batches = @batches.where("batch_number LIKE concat('%', ?, '%')", params[:batch_number]) unless params[:batch_number].blank?
    @batches = @batches.joins(samples: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?

    #paginate batches
    @batches = perform_pagination(@batches)
  end

  def new_sample_or_batch

  end

  def new
    @batch_form = BatchForm.new()
    @can_edit_sample_quantity = true
  end

  def create
    @batch_form = BatchForm.new(batch_params.merge({institution: @navigation_context.institution}))

    if @batch_form.create
      redirect_to batches_path, notice: 'Batch was successfully created.'
    else
      @can_edit_sample_quantity = true
      render action: 'new'
    end
  end

  def edit
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.edit(batch)
    @can_edit_sample_quantity = false

    # TODO: Implement user authorized to delete
    @can_delete = true
  end

  def update
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.edit(batch)

    if @batch_form.update(batch_params, remove_samples_params)
      redirect_to batches_path, notice: 'Batch was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @batch = Batch.find(params[:id])
    # TODO:
    # return unless authorize_resource(@patient, DELETE_PATIENT)

    @batch.destroy

    redirect_to batches_path, notice: 'Batch was successfully deleted.'
  end

  def add_sample
    @batch_form = BatchForm.edit(Batch.find(params[:id]))
    @batch_form.add_sample

    redirect_to edit_batch_path(@batch_form), notice: 'New sample was added successfully.'
  end

  def bulk_destroy
    batch_ids = params[:batch_ids]

    if batch_ids.blank?
      redirect_to batches_path, notice: 'Select at least one batch to destroy.'
      return
    end

    Batch.where(id: batch_ids).destroy_all

    redirect_to batches_path, notice: 'Batches were successfully deleted.'
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
      :samples_quantity
    )
  end

  def remove_samples_params
    (params[:destroy_sample_ids] || []).map(&:to_i)
  end
end
