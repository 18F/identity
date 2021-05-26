module AccountReset
  class DeleteAccountController < ApplicationController
    def show
      render :show and return unless token

      result = AccountReset::ValidateGrantedToken.new(token).call
      analytics.track_event(Analytics::ACCOUNT_RESET, result.to_h)

      result.success? ? handle_valid_token : handle_invalid_token(result)
    end

    def delete
      granted_token = session.delete(:granted_token)
      result = AccountReset::DeleteAccount.new(granted_token).call
      analytics.track_event(Analytics::ACCOUNT_RESET, result.to_h.except(:email))

      result.success? ? handle_successful_deletion(result) : handle_invalid_token(result)
    end

    private

    def token
      params[:token]
    end

    def handle_valid_token
      session[:granted_token] = token
      redirect_to url_for
    end

    def handle_invalid_token(result)
      flash[:error] = result.errors[:token].first
      redirect_to root_url
    end

    def handle_successful_deletion(result)
      sign_out
      flash[:email] = result.extra[:email]
      redirect_to account_reset_confirm_delete_account_url
    end
  end
end
