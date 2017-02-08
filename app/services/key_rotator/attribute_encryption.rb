module KeyRotator
  class AttributeEncryption
    ATTRIBUTES = [:phone, :otp_secret_key].freeze

    def initialize(user)
      @user = user
      self.new_cost = Figaro.env.attribute_cost
      self.encryptor = Pii::PasswordEncryptor.new
    end

    def rotate
      user.update_columns(encrypted_attributes)
    end

    private

    attr_accessor :encryptor, :new_cost
    attr_reader :user

    def uak
      @_uak ||= EncryptedAttribute.new_user_access_key(cost: new_cost)
    end

    def encrypted_attributes
      encrypted_email_attributes.merge!(other_encrypted_attributes)
    end

    def encrypted_email_attributes
      email = EncryptedAttribute.new_from_decrypted(user.email, uak)
      { encrypted_email: email.encrypted, attribute_cost: new_cost }
    end

    def other_encrypted_attributes
      ATTRIBUTES.each_with_object({}) do |attribute, result|
        plain_attribute = user.public_send(attribute)
        next unless plain_attribute

        result[:"encrypted_#{attribute}"] = EncryptedAttribute.new_from_decrypted(
          plain_attribute,
          uak
        ).encrypted
      end
    end
  end
end
