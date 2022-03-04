require "spec_helper"

RSpec.describe SampleTransfer, type: :model do
  let(:sample) { Sample.make }
  let(:sender) { Institution.make }
  let(:receiver) { Institution.make }

  it "sets sender institution from sample" do
    expect(SampleTransfer.new(sample: sample).sender_institution).to eq sample.institution
  end

  it "validates" do
    transfer = SampleTransfer.new(sample: sample, receiver_institution: receiver, sender_institution: sender)
    expect(transfer).to be_valid
  end

  describe ".within" do
    it "selects by sender institution" do
      transfer = SampleTransfer.make!
      expect(SampleTransfer.within(transfer.sender_institution)).to match_array [transfer]
    end

    it "selects by receiver institution" do
      transfer = SampleTransfer.make!
      expect(SampleTransfer.within(transfer.receiver_institution)).to match_array [transfer]
    end

    it "rejects other institution" do
      SampleTransfer.make!
      expect(SampleTransfer.within(Institution.make!)).to be_empty
    end
  end

  describe "#confirm" do
    it "sets confirmed_at" do
      transfer = SampleTransfer.make
      expect(transfer).not_to be_confirmed

      Timecop.freeze do
        expect(transfer.confirm).to be true
        expect(transfer.confirmed_at).to eq Time.now
      end

      expect(transfer).to be_confirmed
      expect(transfer).to be_changed
    end

    it "returns false if already confirmed" do
      transfer = SampleTransfer.make(:confirmed)

      expect {
        expect(transfer.confirm).to be false
      }.not_to change { transfer.confirmed_at }
    end
  end

  describe "#confirm!" do
    it "sets confirmed_at" do
      transfer = SampleTransfer.make
      expect(transfer).not_to be_confirmed

      Timecop.freeze do
        expect(transfer.confirm!).to be true
        expect(transfer.confirmed_at).to eq Time.now
      end

      expect(transfer).to be_confirmed
      expect(transfer).not_to be_changed
    end

    it "raises if already confirmed" do
      transfer = SampleTransfer.make(:confirmed)

      expect {
        expect { transfer.confirm! }.to raise_error(ActiveRecord::RecordNotSaved)
      }.not_to change { transfer.confirmed_at }
    end
  end

  describe "#confirm_and_apply" do
    it "confirms and assigns institution" do
      transfer = SampleTransfer.make
      expect(transfer).not_to be_confirmed

      Timecop.freeze do
        expect(transfer.confirm_and_apply).to be true
        expect(transfer.confirmed_at).to eq Time.now
      end

      transfer.sample.reload
      expect(transfer.sample.institution).to eq(transfer.receiver_institution)
      expect(transfer).to be_confirmed
      expect(transfer).not_to be_changed
    end

    it "returns false if already confirmed" do
      transfer = SampleTransfer.make(:confirmed)

      expect {
        expect(transfer.confirm_and_apply).to be false
      }.not_to change { transfer.confirmed_at }
    end
  end

  describe "#confirm_and_apply!" do
    it "confirms and assigns institution" do
      transfer = SampleTransfer.make
      expect(transfer).not_to be_confirmed

      Timecop.freeze do
        transfer.confirm_and_apply!
        expect(transfer.confirmed_at).to eq Time.now
      end

      transfer.sample.reload
      expect(transfer.sample.institution).to eq(transfer.receiver_institution)
      expect(transfer).to be_confirmed
      expect(transfer).not_to be_changed
    end

    it "returns false if already confirmed" do
      transfer = SampleTransfer.make(:confirmed)

      expect {
        expect { transfer.confirm_and_apply! }.to raise_error(ActiveRecord::RecordNotSaved)
      }.not_to change { [transfer.confirmed_at, transfer.sample.institution] }
    end
  end
end
