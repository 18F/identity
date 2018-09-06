class AuthAppConfiguration
  # This is a wrapping class that lets us interface with the auth app configuration in a manner
  # consistent with phone and webauthn configurations.
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def mfa_enabled?
    AuthAppLoginOptionPolicy.new(user).configured?
  end

  def selection_presenters
    if mfa_enabled?
      [TwoFactorAuthentication::AuthAppSelectionPresenter.new(self)]
    else
      []
    end
  end
end
