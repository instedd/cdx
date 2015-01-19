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
    before { subject.use! }

    it { subject.used?.should be_true }
  end
end