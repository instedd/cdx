require 'spec_helper'

describe ActivationToken do
  let!(:device) { Device.make }
  let!(:token) { ActivationToken.create!(device: device) }

  describe 'new' do
    it 'generates the token value' do
      expect(token.value).to match /[A-Z0-9]{16}/
    end
  end

  describe '#used?' do
    context 'when there is no activation' do
      it { expect(token.used?).to eq(false) }
    end
    context 'when there is an activation' do
      let!(:activation) { Activation.create(activation_token: token) }
      it { expect(token.used?).to eq(true) }
    end
  end

  describe '#client_id' do
    it { expect(token.client_id).not_to be_nil }
  end

  describe '#use!' do
    let!(:settings) { token.use!(SampleSshKey) }
    context 'when it is unused' do
      it { expect(token.used?).to eq(true) }
      it { expect(token.activation).not_to be_nil }

      it { expect(settings[:host]).to eq('localhost') }
      it { expect(settings[:port]).to eq(2222) }
      it { expect(settings[:user]).to eq('cdx-sync') }
      it { expect(settings[:inbox_dir]).to eq('inbox') }
      it { expect(settings[:outbox_dir]).to eq('outbox') }
    end
    context 'when it was used' do
      it { expect { token.use!(SampleSshKey) }.to raise_error(ActiveRecord::RecordInvalid) }
    end
  end
end
