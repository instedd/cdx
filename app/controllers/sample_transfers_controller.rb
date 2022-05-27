class SampleTransfersController < ApplicationController
  def index
    @sample_transfers = SampleTransfer
      .within(@navigation_context.institution)
      .includes(transfer_package: [:receiver_institution, :sender_institution], sample: [:sample_identifiers])
      .order(created_at: :desc)

    @sample_transfers = @sample_transfers.joins(sample: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @sample_transfers = @sample_transfers.joins(:sample).joins("LEFT JOIN batches ON batches.id = samples.batch_id").where("batches.batch_number LIKE concat('%', ?, '%') OR samples.old_batch_number LIKE concat('%', ?, '%')", params[:batch_number], params[:batch_number]) unless params[:batch_number].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.specimen_role = ?", params[:specimen_role]) unless params[:specimen_role].blank?

    @sample_transfers = perform_pagination(@sample_transfers)
      .preload(transfer_package: %i[sender_institution receiver_institution], sample: %i[batch qc_info])
      .map { |transfer| SampleTransferPresenter.new(transfer, @navigation_context) }
  end
end
