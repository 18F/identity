module Idv
  class AddressController < ApplicationController
    include IdvSession

    before_action :confirm_two_factor_authenticated
    before_action :confirm_pii_from_doc

    def new
      analytics.track_event(Analytics::IDV_ADDRESS_VISIT)
    end

    def update
      form_result = idv_form.submit(profile_params)
      analytics.track_event(Analytics::IDV_ADDRESS_SUBMITTED, form_result.to_h)
      form_result.success? ? success : failure
    end

    private

    def confirm_pii_from_doc
      @pii = user_session.dig('idv/doc_auth', 'pii_from_doc')
      return if @pii.present?
      redirect_to idv_doc_auth_url
    end

    def idv_form
      Idv::AddressForm.new(
        user: current_user,
        previous_params: idv_session.previous_profile_step_params,
      )
    end

    def success
      profile_params.each { |key, value| user_session['idv/doc_auth']['pii_from_doc'][key] = value }
      redirect_to idv_doc_auth_url
    end

    def failure
      redirect_to idv_address_url
    end

    def profile_params
      params.require(:idv_form).permit(Idv::AddressForm::ATTRIBUTES)
    end
  end
end
