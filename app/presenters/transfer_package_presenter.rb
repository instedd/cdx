class TransferPackagePresenter
  attr_reader :transfer_package, :context, :current_user

  def initialize(transfer_package, context)
    @transfer_package = transfer_package
    @context = context
  end

  # TODO(Rails 5.1): Use delegate_missing
  delegate :uuid, :recipient, :confirmed_at, :confirmed?, :created_at, :receiver_institution, :sender_institution, :sample_transfers, :samples, to: :transfer_package

  def receiver?
    context.institution == transfer_package.receiver_institution
  end

  def sender?
    context.institution == transfer_package.sender_institution
  end

  def other_institution
    if sender?
      transfer_package.receiver_institution
    elsif receiver?
      transfer_package.sender_institution
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

  delegate :to_param, :model_name, :to_key, :persisted?, to: :transfer_package

  def to_model
    self
  end
end
