require 'spec_helper'

describe Api::ActivationsController do

  describe '#create' do
    before { post :create, { token: '12345', public_key: SampleSshKey }, format: :json  }

    context 'when token exists and device secret key is valid' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      it { JSON.parse(response.body)['status'].should eq('success') }
    end

    context 'when token exists but device secret changed' do
      let!(:activation_token) { ActivationToken.make(value: '12345') }
      before { activation_token.device.secret_key = 'a new secret key' }
      it { JSON.parse(response.body)['status'].should eq('failure') }
    end

    context 'when token does not exist' do
      it { JSON.parse(response.body)['status'].should eq('failure') }
    end
  end
end