class SampleTransfersController < ApplicationController
  def index
    @sample_transfers = SampleTransfer
      .within(@navigation_context.institution)
      .includes(:receiver_institution, :sender_institution, sample: [:sample_identifiers])

    @sample_transfers = @sample_transfers.joins(sample: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_id]) unless params[:sample_id].blank?
    @sample_transfers = @sample_transfers.joins(sample: :batch).where("batches.batch_number LIKE concat('%', ?, '%')", params[:batch_number]) unless params[:batch_number].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.isolate_name LIKE concat('%', ?, '%')", params[:isolate_name]) unless params[:isolate_name].blank?
    @sample_transfers = @sample_transfers.joins(:sample).where("samples.specimen_role = ?", params[:specimen_role]) unless params[:specimen_role].blank?

    @sample_transfers = perform_pagination(@sample_transfers)
    @sample_transfers = @sample_transfers.map { |t| SampleTransferPresenter.new(t, @navigation_context) }
  end
end
