require 'spec_helper'

describe "ActivationToken" do
  let!(:device) { Device.make! }
  let!(:token) { device.new_activation_token.tap { device.save! } }

  describe 'new' do
    it 'generates the token value' do
      expect(token).to match /[A-Z0-9]{16}/
    end
  end

  describe '#use_activation_token_for_ssh_key!' do
    let!(:settings) { device.use_activation_token_for_ssh_key!(SampleSshKey) }
    context 'when it is unused' do
      it { expect(device.activation_token).to be_nil }

      it { expect(settings[:host]).to eq('localhost') }
      it { expect(settings[:port]).to eq(2222) }
      it { expect(settings[:user]).to eq('cdx-sync') }
      it { expect(settings[:inbox_dir]).to eq('inbox') }
      it { expect(settings[:outbox_dir]).to eq('outbox') }
    end
  end
end
