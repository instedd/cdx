class SampleTransferPresenter
  attr_reader :transfer, :context, :current_user

  delegate_missing_to :transfer

  def initialize(transfer, context)
    @transfer = transfer
    @context = context
  end

  def receiver?
    context.institution == transfer.receiver_institution
  end

  def sender?
    context.institution == transfer.sender_institution
  end

  def other_institution
    if sender?
      transfer.receiver_institution
    elsif receiver?
      transfer.sender_institution
    else
      nil
    end
  end

  def status
    confirmed? ? "confirmed" : "in-transit"
  end

  def relation
    if receiver?
      "receiver"
    elsif sender?
      "sender"
    end
  end

  def sample_uuid
    if sender? || confirmed?
      sample.uuid
    else
      sample.partial_uuid + "XXXX"
    end
  end

  def recipient
    transfer_package.try(&:recipient)
  end
end
