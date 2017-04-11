class ProfileController < ApplicationController
  before_action :confirm_two_factor_authenticated
  layout 'card_wide'

  def index
    cacher = Pii::Cacher.new(current_user, user_session)

    @view_model = ProfileIndex.new(
      decrypted_pii: cacher.fetch,
      personal_key: flash[:personal_key],
      current_user: current_user
    )
  end
end
