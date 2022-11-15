module MessageEncryption
  require 'securerandom'

  ALGORITHM = "aes-256-cbc" # TODO: migrate to aes-256-gcm (default in encryptor 2.x)
  DEFAULT_IV = "\xD7\xCA\xD5\x9D\x1D\xC0I\x01Sf\xC8\xFBa\x88\xE1\x03"
  DEFAULT_SALT = "1403203711"

  def self.encrypt string
    Encryptor.encrypt string, :algorithm => ALGORITHM, :key => secret_key, :iv => iv, :salt => salt unless string.blank?
  end

  def self.decrypt string
    unless string.blank?
      Encryptor.decrypt(string, :algorithm => ALGORITHM, :key => secret_key, :iv => iv, :salt => salt)
    else
      ''
    end
  end

  def self.hash string
    (Digest::SHA2.new << string).to_s unless string.blank?
  end

  def self.secure_random length
    Base58.encode(SecureRandom.random_number(58**length))
  end

  def self.reencrypt(string, old_key:, old_iv: DEFAULT_IV, old_salt: DEFAULT_SALT, new_key:, new_iv: DEFAULT_IV, new_salt: DEFAULT_SALT)
    return '' if string.blank?
    plain = Encryptor.decrypt(string, :algorithm => ALGORITHM, :key => old_key, :iv => old_iv, :salt => old_salt)
    Encryptor.encrypt(plain, :algorithm => ALGORITHM, :key => new_key, :iv => new_iv, :salt => new_salt) unless plain.blank?
  end

  private

  def self.secret_key
    ENV['MESSAGE_SECRET_KEY'] || Devise.secret_key
  end

  def self.iv
    # OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
    ENV['MESSAGE_IV'] || DEFAULT_IV
  end

  def self.salt
    # Time.now.to_i.to_s
    ENV['MESSAGE_SALT'] || DEFAULT_SALT
  end
end
