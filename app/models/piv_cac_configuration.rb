class PivCacConfiguration
  # This is a wrapping class that lets us interface with the piv/cac configuration in a manner
  # consistent with phone and webauthn configurations.
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def mfa_enabled?
    PivCacLoginOptionPolicy.new(user).enabled?
  end

  def mfa_confirmed?(proposed_uuid)
    user && proposed_uuid && user.x509_dn_uuid == proposed_uuid
  end

  def mfa_available?
    PivCacLoginOptionPolicy.new(user).available?
  end

  def selection_presenters
    if mfa_enabled?
      [TwoFactorAuthentication::PivCacSelectionPresenter.new(self)]
    else
      []
    end
  end
end
