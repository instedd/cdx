class BatchesController < ApplicationController

  def index
    @batches = Batch.all.order('created_at DESC')

    @batches = @batches.where("isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?

    #paginate batches
    @batches = perform_pagination(@batches)
  end

  def new
    @batch = Batch.new()

    @date_produced_placeholder = date_produced_placeholder
  end

  def create
    params = batch_params

    samples_quantity = params.delete(:samples_quantity).to_i

    @batch = Batch.new(params.merge({
      institution: @navigation_context.institution
    }))

    @batch.laboratory_samples = (1..samples_quantity).map {
      LaboratorySample.new({
        institution: @navigation_context.institution,
        sample_type: 'specimen' # TODO: remove sample_type when adding QC-check
      })
    }

    if @batch.save
      redirect_to batches_path, notice: 'Batch was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def date_produced_placeholder
    date_format[:placeholder]
  end

  def batch_params
    params.require(:batch).permit(:isolate_name, :date_produced, :inactivation_method, :volume, :lab_technician, :samples_quantity)
  end
end
