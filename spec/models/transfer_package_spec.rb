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

  it "validates sample transfer" do
    transfer = TransferPackage.make
    transfer.sample_transfers.new sample: Sample.make(institution: transfer.sender_institution, specimen_role: 'q')

    expect(transfer).not_to be_valid
    expect(transfer.errors["sample_transfers.sample"]).to eq ["Can't transfer QC sample"]
  end
end
