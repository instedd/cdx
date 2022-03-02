class SampleTransfersController < ApplicationController
  def index
    @sample_transfers = SampleTransfer
      .within(@navigation_context.institution)
      .includes(:receiver_institution, :sender_institution, sample: [:sample_identifiers])
      .ordered_by_creation

    @sample_transfers = @sample_transfers.joins(sample: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @sample_transfers = @sample_transfers.joins(sample: :batch).where("batches.batch_number LIKE concat('%', ?, '%')", params[:batch_number]) unless params[:batch_number].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.specimen_role = ?", params[:specimen_role]) unless params[:specimen_role].blank?

    @sample_transfers = perform_pagination(@sample_transfers)
    @sample_transfers = @sample_transfers.map { |t| SampleTransferPresenter.new(t, @navigation_context) }
  end

  def create
    new_owner = Institution.find_by(uuid: params["institution_id"])
    if new_owner.nil?
      flash[:error] = "Destination Institution does not exists"
      render json: { status: :error }, status: 404
    else
      if create_transfer(new_owner, params["samples"])
        flash[:success] = "All samples have been transferred successfully."
        render json: { status: :ok }
      else
        flash[:error] = "Samples transfer failed."
        render json: { status: :error }, status: 500
      end
    end
  end

  def confirm
    transfer = SampleTransfer.find(params[:sample_transfer_id])

    unless transfer.receiver_institution == @navigation_context.institution
      render json: { status: "error" }, status: :not_found
      return
    end

    resource = {
      resource_type: "sample",
      resource_id: transfer.sample.id,
      institution_id: @navigation_context.institution.id,
      site_id: @navigation_context.site.try(&:uuid),
    }
    unless ComputedPolicy.authorize_instance(UPDATE_SAMPLE, resource, current_user)
      log_authorization_warn SampleTransfer, UPDATE_SAMPLE

      render json: { status: "error" }, status: :forbidden
      return
    end

    transfer.confirm_and_apply!

    flash[:success] = "Sample has been confirmed."

    render json: { status: :ok }
  end

  private

  def create_transfer(new_owner, samples)
    samples = Sample.joins(:sample_identifiers).where("sample_identifiers.uuid": samples)
    Sample.transaction do
      samples.each do |to_transfer|
        raise "User not authorized for transferring Samples " unless authorize_resource?(to_transfer, UPDATE_SAMPLE)

        unless to_transfer.batch.nil?
          if params["includes_qc_info"] == "true"
            qc_info = create_qc_info(to_transfer)
            to_transfer.qc_info_id = qc_info.id if qc_info
          end
        end

        to_transfer.start_transfer_to(new_owner)
      end
    end

    true
  rescue => exception
    Raven.capture_exception(exception)

    false
  end

  def create_qc_info(sample)
    sample_qc = sample.batch.qc_sample
    return if sample_qc.nil?

    qc_info = QcInfo.find_or_duplicate_from(sample_qc)
    qc_info.samples << sample
    qc_info.save!
    qc_info
  end
end
