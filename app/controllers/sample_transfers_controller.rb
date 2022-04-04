class SampleTransfersController < ApplicationController
  helper_method :can_confirm_transfer?
  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :ensure_context, :only => :create

  def index
    @sample_transfers = SampleTransfer
      .within(@navigation_context.institution)
      .includes(:receiver_institution, :sender_institution, sample: [:sample_identifiers])
      .ordered_by_creation

    @sample_transfers = @sample_transfers.joins(sample: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @sample_transfers = @sample_transfers.joins(:sample).joins("LEFT JOIN batches ON batches.id = samples.batch_id").where("batches.batch_number LIKE concat('%', ?, '%') OR samples.old_batch_number LIKE concat('%', ?, '%')", params[:batch_number], params[:batch_number]) unless params[:batch_number].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.specimen_role = ?", params[:specimen_role]) unless params[:specimen_role].blank?

    @sample_transfers = perform_pagination(@sample_transfers)
      .preload(:transfer_package, :sample, :sender_institution, :receiver_institution)
      .map { |transfer| SampleTransferPresenter.new(transfer, @navigation_context) }
  end

  def create
    new_owner = Institution.find_by(uuid: params["institution_id"])
    if new_owner.nil?
      flash[:error] = "Destination Institution does not exists."
      redirect_to samples_path
    else
      if create_transfer(new_owner, params["samples"])
        flash[:notice] =  "All samples have been transferred successfully."
        redirect_to samples_path
      else
        flash[:error] = "Samples transfer failed."
        redirect_to samples_path
      end
    end
  end

  def confirm
    transfer = SampleTransfer.with_receiver(@navigation_context.institution).find(params[:sample_transfer_id])

    return unless authorize_resource(confirmation_resource(transfer), UPDATE_SAMPLE)

    unless transfer.confirm_and_apply
      flash[:error] = "Sample transfer has already been confirmed"

      render json: { status: "error" }, status: :bad_request
      return
    end

    flash[:success] = "Sample has been confirmed."

    render json: { status: :ok }
  end

  private

  def can_confirm_transfer?(sample_transfer)
    authorize_resource?(confirmation_resource(sample_transfer.sample), UPDATE_SAMPLE)
  end

  def confirmation_resource(sample)
    {
      resource_type: "sample",
      resource_id: sample.id,
      institution_id: @navigation_context.institution.id,
      site_id: @navigation_context.site.try(&:uuid),
    }
  end

  def create_transfer(new_owner, sample_uuids)
    samples = Sample.find_all_by_any_uuid(sample_uuids)

    Sample.transaction do
      package = TransferPackage.sending_to(new_owner, transfer_package_params)

      samples.each do |sample|
        raise "User not authorized for transferring Samples " unless authorize_resource?(sample, UPDATE_SAMPLE)
        raise "QC Samples can't be transferred" if sample.is_quality_control?

        package.add!(sample)
      end
    end

    true
  rescue => exception
    Raven.capture_exception(exception)

    false
  end

  def transfer_package_params
    params.permit(:recipient, :includes_qc_info)
  end
end
