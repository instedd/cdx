require 'spec_helper'

describe MessageEncryption do

  it "should reencrypt data" do
    new_key = MessageEncryption.secure_random(128)
    encrypted = MessageEncryption.encrypt "PLAIN_DATA"
    reencrypted = MessageEncryption.reencrypt encrypted, old_key: MessageEncryption.send(:secret_key), new_key: new_key

    expect(MessageEncryption).to receive(:secret_key).and_return(new_key)
    decrypted = MessageEncryption.decrypt reencrypted
    expect(decrypted).to eq("PLAIN_DATA")
  end

end
