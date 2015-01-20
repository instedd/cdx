require 'spec_helper'

describe ActivationToken do
  let!(:device) { Device.make(secret_key: '74ee5b6e-f64c-17d3-49d6-28ff59b1b1d3') }
  let!(:token) { ActivationToken.create!(device: device, value: 'foobar') }

  describe '#used?' do
    context 'when there is no activation' do
      it { token.used?.should be_false }
    end
    context 'when there is an activation' do
      let!(:activation) { Activation.create(activation_token: token) }
      it { token.used?.should be_true }
    end
  end

  describe '#client_id' do
    it { token.client_id.should_not be_nil }
  end

  describe '#use!' do
    let!(:settings) { token.use!(SampleSshKey) }
    context 'when it is unused' do
      it { token.used?.should be_true }
      it { token.device.ssh_keys.should_not be_empty }
      it { token.activation.should_not be_nil }

      it { settings[:host].should eq('localhost') }
      it { settings[:port].should eq(2222) }
      it { settings[:user].should eq('cdx-sync') }
      it { settings[:inbox_dir].should end_with('74ee5b6e-f64c-17d3-49d6-28ff59b1b1d3/inbox') }
      it { settings[:outbox_dir].should end_with('74ee5b6e-f64c-17d3-49d6-28ff59b1b1d3/outbox') }
    end
    context 'when it was used' do
      it { expect { token.use!(SampleSshKey) }.to raise_error }
    end
  end

  describe '#client_id_valid?' do
    context 'when client_id is current device.secret_key' do
      it { token.client_id_valid?.should be_true }
    end
    context 'when client_id is not current device.secret_key' do
      before { device.update! secret_key: 'a_new_secret_key' }
      it { token.client_id_valid?.should be_false }
    end
  end
end