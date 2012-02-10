require 'fast-aes'
require 'active_support/secure_random'
require 'base64'

module Encryption
  #Basic AES symmetric encryption functions
  #based on http://snippets.dzone.com/posts/show/4975

  def self.encrypt(text)
    aes  = FastAES.new(Settings.aes_crypt_key)
    salt = SecureRandom.base64(16)
    Base64.encode64(aes.encrypt(salt + text))
  end

  def self.decrypt(data)
    aes  = FastAES.new(Settings.aes_crypt_key)
    output = aes.decrypt(Base64.decode64(data))
    text = output[24..-1]
  end
end