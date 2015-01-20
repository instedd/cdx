require 'spec_helper'

describe Api::ActivationsController do

  describe '#create' do
    before { post :create, { token: '12345', public_key: SampleSshKey }, format: :json  }
    let(:response_json) { JSON.parse(response.body) }

    context 'when token exists and device secret key is valid' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      it { response_json['status'].should eq('success') }
      it { response_json['message'].should eq('Device activated') }
    end

    context 'when token exists but device secret changed' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      before { activation_token.device.secret_key = 'a new secret key' }
      it { response_json['status'].should eq('failure') }
      it { response_json['message'].should eq('Client id expired') }
    end

    context 'when token exists but was used' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      before { activation_token.use!(SampleSshKey) }
      it { response_json['status'].should eq('failure') }
      it { response_json['message'].should eq('Activation token already used') }
    end

    context 'when token does not exist' do
      it { response_json['status'].should eq('failure') }
      it { response_json['message'].should eq('Invalid activation token') }
    end
  end
end