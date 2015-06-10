require 'spec_helper'

describe Device do
  it { should validate_presence_of :device_model }
  it { should validate_presence_of :name }
  it { should validate_presence_of :institution }


  context 'secret key' do
    let(:device) { Device.new }

    before(:each) do
      MessageEncryption.should_receive(:secure_random).and_return('abc')
    end

    it 'should tell plain secret key' do
      device.set_key

      device.plain_secret_key.should eq('abc')
    end

    it 'should store hashed secret key' do
      device.set_key

      device.secret_key_hash.should eq(MessageEncryption.hash 'abc')
    end
  end
end
