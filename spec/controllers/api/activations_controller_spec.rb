require 'spec_helper'

describe Api::ActivationsController do
  setup_fixtures do
    @device = Device.make!
  end

  shared_context :set_device_token do
    before { device.new_activation_token('12345').tap { device.save! } }
  end

  shared_context :do_ssh_key_post do
    before { post :create, { token: '12345', public_key: SampleSshKey }, format: :json  }
  end

  let(:response_json) { JSON.parse(response.body) }

  describe '#create' do
    context 'when token exists and device secret key is valid' do
      include_context :set_device_token
      include_context :do_ssh_key_post

      it { expect(response_json['status']).to eq('success') }
      it { expect(response_json['message']).to eq('Device activated') }
      it { device.reload; expect(device.activation_token).to be_nil }
    end

    context 'when token exists and device secret key is valid ignoring case and dashes' do
      let!(:activation_token) { device.new_activation_token('AAAABBBB').tap { device.save! } }
      before { post :create, { token: 'aaaa-bbbb', public_key: SampleSshKey }, format: :json  }

      it { expect(response_json['status']).to eq('success') }
      it { expect(response_json['message']).to eq('Device activated') }
    end

    context 'when token exists but device uuid does not match' do
      include_context :set_device_token
      before { device.tap(&:set_key).save }
      include_context :do_ssh_key_post

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Invalid activation token') }
    end

    context 'when token exists but was used' do
      include_context :set_device_token
      before { device.use_activation_token_for_ssh_key!(SampleSshKey) }
      include_context :do_ssh_key_post

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Invalid activation token') }
    end

    context 'when token does not exist' do
      include_context :do_ssh_key_post

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Invalid activation token') }
    end

    context 'when no parameter is supplied' do
      include_context :set_device_token
      before { post :create, { token: '12345' }, format: :json }

      it { expect(response_json['status']).to eq('failure') }
      it { expect(response_json['message']).to eq('Missing public_key or generate_key parameter') }
    end

    context 'when device key is requested' do
      include_context :set_device_token
      before { post :create, { token: '12345', generate_key: true }, format: :json }

      it { expect(response_json['status']).to eq('success') }
      it { expect(response_json['settings']['device_uuid']).to eq(device.uuid) }
      it { expect(response_json['settings']['device_key']).to_not be_blank }
      it { expect(device.reload.activation_token).to be_nil }
      it { expect(device.reload.secret_key_hash).to_not be_blank }
    end
  end
end
