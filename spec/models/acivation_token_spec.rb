require 'spec_helper'

describe ActivationToken do
  let(:device) { Device.make }
  subject { ActivationToken.create!(device: device, value: 'foobar') }


  describe '#used?' do
    context 'when there is no activation' do
      it { subject.used?.should be_false }
    end
    context 'when there is an activation' do
      let!(:activation) { Activation.create(activation_token: subject) }
      it { subject.used?.should be_true }
    end
  end

  describe '#device_secret_key' do
    it { subject.device_secret_key.should_not be_nil }
  end

  describe '#use!' do
    context 'when it is unused' do
      before { subject.use!(SampleSshKey) }
      it { subject.used?.should be_true }
      it { subject.device.ssh_keys.should_not be_empty }
      it { subject.activation.should_not be_nil }
    end
    context 'when it was used' do
      before { subject.use!(SampleSshKey) }
      it { expect { subject.use!(SampleSshKey) }.to raise_error }
    end
  end

  describe '#device_secret_key_valid?' do
    context 'when device_secret_key is current device.secret_key' do
      it { subject.device_secret_key_valid?.should be_true }
    end
    context 'when device_secret_key is not current device.secret_key' do
      before { device.secret_key = 'a_new_secret_key' }
      it { subject.device_secret_key_valid?.should be_false }
    end
  end
end