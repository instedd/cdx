require 'spec_helper'

describe Api::ActivationsController do
  shared_context :do_post do
    before { post :create, { token: '12345', public_key: SampleSshKey }, format: :json  }
    let(:response_json) { JSON.parse(response.body) }
  end

  describe '#create' do
    context 'when token exists and device secret key is valid' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      include_context :do_post

      it { response_json['status'].should eq('success') }
      it { response_json['message'].should eq('Device activated') }
    end

    context 'when token exists but device uuid does not match' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      before { activation_token.device.tap(&:set_key).save }
      include_context :do_post

      it { response_json['status'].should eq('failure') }
      it { response_json['message'].should eq('Invalid activation token') }
    end

    context 'when token exists but was used' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      before { activation_token.use!(SampleSshKey) }
      include_context :do_post

      it { response_json['status'].should eq('failure') }
      it { response_json['message'].should eq('Activation token already used') }
    end

    context 'when token does not exist' do
      include_context :do_post

      it { response_json['status'].should eq('failure') }
      it { response_json['message'].should eq('Invalid activation token') }
    end
  end
end
