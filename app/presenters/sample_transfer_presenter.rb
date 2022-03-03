class SampleTransferPresenter
  attr_reader :transfer, :context, :current_user

  def initialize(transfer, context)
    @transfer = transfer
    @context = context
  end

  # TODO(Rails 5.1): Use delegate_missing
  delegate :sample, :confirmed_at, :confirmed?, :created_at, :receiver_institution, :sender_institution, to: :transfer

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

  def can_confirm?
    true
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
end
