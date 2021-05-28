class BatchesController < ApplicationController

  def index
    @batches = Batch.all.order('created_at DESC')

    @batches = @batches.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?

    #paginate batches
    @batches = perform_pagination(@batches)
  end

  def new
    @batch_form = BatchForm.new()
  end

  def create
    @batch_form = BatchForm.new(batch_params.merge({institution: @navigation_context.institution}))

    if @batch_form.save
      redirect_to batches_path, notice: 'Batch was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def batch_params
    params.require(:batch).permit(:isolate_name, :date_produced, :inactivation_method, :volume, :lab_technician, :samples_quantity)
  end
end
