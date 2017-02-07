class RemoveUnusedEncryptedOtpSecretColumns < ActiveRecord::Migration
  def change
    remove_column :users, :encrypted_otp_secret_key_iv, :string
    remove_column :users, :encrypted_otp_secret_key_salt, :string
  end
end
