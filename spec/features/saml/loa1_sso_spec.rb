require 'rails_helper'

feature 'LOA1 Single Sign On' do
  include SamlAuthHelper

  context 'First time registration' do
    scenario 'taken to agency handoff page when sign up flow complete' do
      allow(FeatureManagement).to receive(:prefill_otp_codes?).and_return(true)
      issuer_url = 'http://localhost:3000'
      saml_authn_request = auth_request.create(saml_settings)

      visit saml_authn_request
      sign_up_and_set_password
      fill_in 'Phone', with: '202-555-1212'
      select_sms_delivery
      enter_2fa_code
      click_acknowledge_recovery_code
      click_on I18n.t('forms.buttons.continue_to', url: issuer_url)

      expect(current_url).to eq saml_authn_request
    end
  end
end
