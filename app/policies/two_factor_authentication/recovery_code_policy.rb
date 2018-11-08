module TwoFactorAuthentication
  class RecoveryCodePolicy
    def initialize(user)
      @user = user
    end

    def configured?
      true
    end

    def enabled?
      configured?
    end

    def visible?
      true
    end

    def available?
      true #FeatureManagement.recovery_codes_enabled? == true
    end

    private

    attr_reader :user
  end
end
