module EventEncryption
  require 'securerandom'

  def self.encrypt string
    Encryptor.encrypt string, :key => secret_key, :iv => iv, :salt => salt unless string.blank?
  end

  def self.decrypt string
    unless string.blank?
      Encryptor.decrypt(string, :key => secret_key, :iv => iv, :salt => salt)
    else
      ''
    end
  end

  def self.hash string
    (Digest::SHA2.new << string).to_s unless string.blank?
  end

  def self.secure_random length
    # min = ('1' + '0' * (length - 1)).to_i(36)
    # max = ('Z' * length).to_i(36)
    # (SecureRandom.random_number(max - min) + min).to_s(36).upcase
    Base64.urlsafe_encode64(SecureRandom.random_bytes(length))
  end

  private

  def self.secret_key
    ENV['EVENT_SECRET_KEY'] || Devise.secret_key
  end

  def self.iv
    # OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
    ENV['EVENT_IV'] || "\xD7\xCA\xD5\x9D\x1D\xC0I\x01Sf\xC8\xFBa\x88\xE1\x03"
  end

  def self.salt
    # Time.now.to_i.to_s
    ENV['EVENT_SALT'] || "1403203711"
  end
end
