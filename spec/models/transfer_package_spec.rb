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

  describe ".save" do
    describe "attach QC info" do
      let(:batch) { Batch.make!(:qc_sample) }
      let(:sample1) { Sample.make(institution: sender, batch: batch) }
      let(:sample2) { Sample.make(institution: sender, batch: batch) }

      it "includes_qc_info: true" do
        transfer = TransferPackage.new(sender_institution: sender, receiver_institution: receiver, includes_qc_info: true)
        transfer.sample_transfers.build(sample: sample1)
        transfer.sample_transfers.build(sample: sample2)
        transfer.save

        sample1.reload
        sample2.reload
        expect(sample1.qc_info).to be_a(QcInfo)
        expect(sample2.qc_info).to be_a(QcInfo)
        expect(sample1.qc_info).to eq sample2.qc_info
      end

      it "includes_qc_info: false" do
        transfer = TransferPackage.new(sender_institution: sender, receiver_institution: receiver, includes_qc_info: false)
        transfer.sample_transfers.build(sample: sample1)
        transfer.sample_transfers.build(sample: sample2)
        transfer.save

        sample1.reload
        sample2.reload
        expect(sample1.qc_info).to be_nil
        expect(sample2.qc_info).to be_nil
      end
    end

    it "updates sample context" do
      site = Site.make(institution: sender)
      sample = Sample.make(institution: sender, site: site)
      transfer = TransferPackage.new(sender_institution: sender, receiver_institution: receiver)
      transfer.sample_transfers.build(sample: sample)
      transfer.save

      sample.reload
      expect(sample.institution).to be_nil
      expect(sample.site).to be_nil
    end
  end

  describe "#confirm" do
    it "sets confirmed_at" do
      transfer = TransferPackage.make
      expect(transfer).not_to be_confirmed

      Timecop.freeze(Time.now.change(usec: 0)) do
        expect(transfer.confirm).to be true
        expect(transfer.confirmed_at).to eq Time.now
      end

      expect(transfer).to be_confirmed
      expect(transfer).to be_changed
    end

    it "returns false if already confirmed" do
      transfer = TransferPackage.make(:confirmed)

      expect {
        expect(transfer.confirm).to be false
      }.not_to change { transfer.confirmed_at }
    end
  end

  describe "#confirm!" do
    it "sets confirmed_at" do
      transfer = TransferPackage.make
      expect(transfer).not_to be_confirmed

      Timecop.freeze(Time.now.change(usec: 0)) do
        expect(transfer.confirm!).to be true
        expect(transfer.confirmed_at).to eq Time.now
      end

      expect(transfer).to be_confirmed
      expect(transfer).not_to be_changed
    end

    it "raises if already confirmed" do
      transfer = TransferPackage.make(:confirmed)

      expect {
        expect { transfer.confirm! }.to raise_error(ActiveRecord::RecordNotSaved)
      }.not_to change { transfer.confirmed_at }
    end
  end
end
