module EventEncryption
  extend ActiveSupport::Concern

  included do
    def decrypt
      self.raw_data = Encryptor.decrypt self.raw_data, :key => secret_key, :iv => iv, :salt => salt
      self.sensitive_data = Oj.load(Encryptor.decrypt(self.sensitive_data, :key => secret_key, :iv => iv, :salt => salt)).with_indifferent_access
      self
    end

    def encrypt
      self.raw_data = Encryptor.encrypt self.raw_data, :key => secret_key, :iv => iv, :salt => salt
      self.sensitive_data = Encryptor.encrypt Oj.dump(self.sensitive_data), :key => secret_key, :iv => iv, :salt => salt
      self
    end

    private

    def secret_key
      'a very secret key'
    end

    def iv
      # OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
      "\xD7\xCA\xD5\x9D\x1D\xC0I\x01Sf\xC8\xFBa\x88\xE1\x03"
    end

    def salt
      # Time.now.to_i.to_s
      "1403203711"
    end
  end
end
