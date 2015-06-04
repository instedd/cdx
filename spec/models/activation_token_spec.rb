require 'spec_helper'

describe ActivationToken do
  let!(:device) { Device.make }
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
      it { token.device.ssh_key.should eq(SshKey.last) }
      it { token.activation.should_not be_nil }

      it { settings[:host].should eq('localhost') }
      it { settings[:port].should eq(2222) }
      it { settings[:user].should eq('cdx-sync') }
      it { settings[:inbox_dir].should eq('inbox') }
      it { settings[:outbox_dir].should eq('outbox') }
    end
    context 'when it was used' do
      it { expect { token.use!(SampleSshKey) }.to raise_error }
    end
  end
end
