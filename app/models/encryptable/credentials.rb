# frozen_string_literal: true

class Encryptable::Credentials < Encryptable
  attr_accessor :cleartext_password, :cleartext_username

  has_many :encryptable_files, class_name: 'Encryptable::File', foreign_key: :credential_id

  validate :credential_id

  def decrypt(team_password)
    decrypt_attr(:username, team_password)
    decrypt_attr(:password, team_password)
  end

  def encrypt(team_password)
    encrypt_attr(:username, team_password)
    encrypt_attr(:password, team_password)
  end

  private

  def credential_id
    if credential_id.present?
      errors.add(:base, 'Credential must not have credential as parent!')
    end
  end

end
