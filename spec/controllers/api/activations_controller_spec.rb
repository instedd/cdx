require 'spec_helper'

describe Api::ActivationsController do
  shared_context :do_post do
    before { post :create, { token: '12345', public_key: SampleSshKey }, format: :json  }
    let(:response_json) { JSON.parse(response.body) }
  end

  let!(:device) { Device.make }

  describe '#create' do
    context 'when token exists and device secret key is valid' do
      let!(:activation_token) { device.new_activation_token('12345').tap { device.save! } }
      include_context :do_post

      it { expect(response_json['status']).to eq('success') }
      it { expect(response_json['message']).to eq('Device activated') }
      it { device.reload; expect(device.activation_token).to be_nil }
    end

    context 'when token exists and device secret key is valid ignoring case and dashes' do
      let!(:activation_token) { device.new_activation_token('AAAABBBB').tap { device.save! } }
      before { post :create, { token: 'aaaa-bbbb', public_key: SampleSshKey }, format: :json  }
      let(:response_json) { JSON.parse(response.body) }

      it { expect(response_json['status']).to eq('success') }
      it { expect(response_json['message']).to eq('Device activated') }
    end

    context 'when token exists but device uuid does not match' do
      let!(:activation_token) { device.new_activation_token('12345').tap { device.save! } }
      before { device.tap(&:set_key).save }
      include_context :do_post

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Invalid activation token') }
    end

    context 'when token exists but was used' do
      let!(:activation_token) { device.new_activation_token('12345').tap { device.save! } }
      before { device.use_activation_token!(SampleSshKey) }
      include_context :do_post

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Invalid activation token') }
    end

    context 'when token does not exist' do
      include_context :do_post

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Invalid activation token') }
    end
  end
end
