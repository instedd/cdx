class BatchesController < ApplicationController

  def index
    @batches = Batch.all.order('created_at DESC')

    @batches = @batches.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?

    #paginate batches
    @batches = perform_pagination(@batches)
  end

  def new
    @batch_form = BatchForm.new()
    @can_edit_sample_quantity = true
  end

  def create
    @batch_form = BatchForm.new(batch_params.merge({institution: @navigation_context.institution}))

    if @batch_form.save
      redirect_to batches_path, notice: 'Batch was successfully created.'
    else
      render action: 'new'
    end
  end

  def edit
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.edit(batch)
    @can_edit_sample_quantity = false
  end

  def update
    batch = Batch.find(params[:id])
    @batch_form = BatchForm.edit(batch)

    if @batch_form.update(batch_params)
      redirect_to batches_path, notice: 'Batch was successfully updated.'
    else
      render action: 'edit'
    end
  end

  private

  def batch_params
    params.require(:batch).permit(:isolate_name, :date_produced, :inactivation_method, :volume, :lab_technician, :samples_quantity)
  end
end
