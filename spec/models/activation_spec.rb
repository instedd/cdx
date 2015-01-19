require 'spec_helper'

describe 'Activation' do
  let(:token) { ActivationToken.make(device_secret_key: '74ee5b6e-f64c-17d3-49d6-28ff59b1b1d3') }
  subject { Activation.create!(activation_token: token) }

  it { subject.settings[:host].should eq('localhost') }
  it { subject.settings[:port].should eq(2222) }
  it { subject.settings[:user].should eq('cdx-sync') }
  it { subject.settings[:inbox_dir].should eq('sync/74ee5b6e-f64c-17d3-49d6-28ff59b1b1d3/inbox') }
  it { subject.settings[:outbox_dir].should eq('sync/74ee5b6e-f64c-17d3-49d6-28ff59b1b1d3/outbox') }
end

