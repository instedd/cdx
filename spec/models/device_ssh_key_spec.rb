require 'spec_helper'

describe DeviceSshKey do
  let(:device) { create(:device) }

  describe '::all_public_keys' do
    before {  device.ssh_keys.create(public_key: 'abcdedf') }

    it { expect(SshDeviceKey.all_public_keys).to eq(['abcdedf']) }
  end
end