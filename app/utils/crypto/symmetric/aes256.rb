# frozen_string_literal: true

require 'openssl'
require 'digest/sha1'

class Crypto::Symmetric::Aes256 < Crypto::Symmetric
  CIPHER = 'AES-256-CBC'
  MAGIC = 'Salted__'
  SALT_LENGTH = 8
  ITERATION_COUNT = 1000

  class << self

    def encrypt(data, key)
      cipher = cipher_encrypt_mode

      # set encryption key
      cipher.key = key

      # return encrypted data
      cipher.update(data) + cipher.final
    end

    def decrypt(data, key)
      cipher = cipher_decrypt_mode

      # set decryption key
      cipher.key = key

      # decrypt data
      decrypted_data = cipher.update(data) + cipher.final
      decrypted_data.force_encoding('UTF-8')
    end

    def encrypt_with_salt(data, key)
      cipher = cipher_encrypt_mode
      salt = generate_salt

      # generates and sets key/iv
      cipher.pkcs5_keyivgen(key, salt, ITERATION_COUNT)

      # encrypt data
      encrypted_private_key = cipher.update(data) + cipher.final

      MAGIC + salt + encrypted_private_key
    end

    def decrypt_with_salt(data, key)
      cipher = cipher_decrypt_mode
      raise 'magic does not match' unless extract_magic_from(data) == MAGIC

      salt = extract_salt_from(data)
      encrypted_data = extract(data)

      # generates and sets key/iv
      cipher.pkcs5_keyivgen(key, salt, ITERATION_COUNT)

      # decrypt data
      cipher.update(encrypted_data) + cipher.final
    rescue StandardError
      raise Exceptions::DecryptFailed
    end

    def random_key
      cipher_encrypt_mode.random_key
    end

    private

    def cipher_encrypt_mode
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.encrypt
      cipher
    end

    def cipher_decrypt_mode
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.decrypt
      cipher
    end

    def generate_salt
      OpenSSL::Random.random_bytes(SALT_LENGTH)
    end

    def extract_magic_from(data)
      data.slice(0, MAGIC.size)
    end

    def extract_salt_from(data)
      data.slice(MAGIC.size, SALT_LENGTH)
    end

    def extract(data)
      data.slice((MAGIC.size + SALT_LENGTH)..-1)
    end
  end
end
