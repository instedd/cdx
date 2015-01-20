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
      ENV['EVENT_SECRET_KEY'] || Devise.secret_key
    end

    def iv
      # OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
      ENV['EVENT_IV'] || "\xD7\xCA\xD5\x9D\x1D\xC0I\x01Sf\xC8\xFBa\x88\xE1\x03"
    end

    def salt
      # Time.now.to_i.to_s
      ENV['EVENT_SALT'] || "1403203711"
    end
  end
end
