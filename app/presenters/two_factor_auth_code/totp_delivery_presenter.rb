module TwoFactorAuthCode
  class TotpDeliveryPresenter < TwoFactorAuthCode::GenericDeliveryModePresenter
    def initialize(data_model)
      super
    end

    def header
      t('devise.two_factor_authentication.header_text')
    end

    def help_text
      t("instructions.2fa.#{delivery_method}.confirm_code",
        email: content_tag(:strong, user.email),
        app: content_tag(:strong, APP_NAME))
    end

    def fallback_links
      [otp_fallback_options, recovery_code_link].compact
    end

    private

    def otp_fallback_options
      t('devise.two_factor_authentication.totp_fallback.text',
        sms_link: sms_link,
        voice_link: voice_link)
    end

    def sms_link
      content_tag(:a, t('devise.two_factor_authentication.totp_fallback.sms_link_text'),
                  href: otp_send_path(otp_delivery_selection_form: { otp_method: 'sms' }))
    end

    def voice_link
      content_tag(:a, t('devise.two_factor_authentication.totp_fallback.voice_link_text'),
                  href: otp_send_path(otp_delivery_selection_form: { otp_method: 'voice' }))
    end
  end
end
