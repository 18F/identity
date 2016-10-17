module Devise
  class TwoFactorAuthenticationController < DeviseController
    include TwoFactorAuthenticatable

    def show
      if current_user.totp_enabled?
        redirect_to login_two_factor_authenticator_path
      else
        @phone_number = decorated_user.masked_two_factor_phone_number
        @otp_delivery_selection_form = OtpDeliverySelectionForm.new
      end
    end

    def send_code
      @otp_delivery_selection_form = OtpDeliverySelectionForm.new

      result = @otp_delivery_selection_form.submit(delivery_params)

      analytics.track_event(:otp_delivery_selection, result)

      if result[:success?]
        handle_valid_delivery_method(delivery_params[:otp_method])
      else
        redirect_to user_two_factor_authentication_path(reauthn: reauthn?)
      end
    end

    private

    def reauthn_param
      otp_form = params.permit(otp_delivery_selection_form: [:reauthn])
      super || otp_form.dig(:otp_delivery_selection_form, :reauthn)
    end

    def handle_valid_delivery_method(method)
      send_user_otp(method)
      resent_message = t("notices.send_code.#{method}")
      flash[:success] = resent_message if session[:code_sent].present?
      session[:code_sent] = 'true'
      redirect_to login_two_factor_path(delivery_method: method, reauthn: reauthn?)
    end

    def send_user_otp(method)
      current_user.create_direct_otp

      job = "#{method.capitalize}OtpSenderJob".constantize

      job.perform_later(
        code: current_user.direct_otp,
        phone: current_user.phone,
        otp_created_at: current_user.direct_otp_sent_at.to_s
      )
    end

    def delivery_params
      params.require(:otp_delivery_selection_form).permit(:otp_method, :resend)
    end
  end
end
