require "spec_helper"

RSpec.describe TransferPackage, type: :model do
  let(:sender) { Institution.make }
  let(:receiver) { Institution.make }

  it ".new" do
    transfer = TransferPackage.new
    expect(transfer).not_to be_valid

    transfer = TransferPackage.new(receiver_institution: receiver, sender_institution: sender)
    expect(transfer).to be_valid
  end
end
