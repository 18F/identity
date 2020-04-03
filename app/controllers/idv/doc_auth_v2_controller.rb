module Idv
  class DocAuthV2Controller < ApplicationController
    before_action :confirm_two_factor_authenticated
    before_action :redirect_if_mail_bounced
    before_action :redirect_if_pending_profile
    before_action :extend_timeout_using_meta_refresh_for_select_paths

    include IdvSession # remove if we retire the non docauth LOA3 flow
    include Flow::FlowStateMachine

    FSM_SETTINGS = {
      step_url: :idv_doc_auth_v2_step_url,
      final_url: :idv_review_url,
      flow: Idv::Flows::DocAuthV2Flow,
      analytics_id: Analytics::DOC_AUTH_V2,
    }.freeze

    def doc_capture_poll
      doc_capture = DocCapture.find_by(user_id: user_id)
      render plain: 'Not authorized', status: :not_authorized if doc_capture.blank?
      if doc_capture.acuant_token.present?
        render plain: 'Complete', status: :ok
      else
        render plain: 'Pending', status: :accepted
      end
    end

    def redirect_if_mail_bounced
      redirect_to idv_usps_url if current_user.decorate.usps_mail_bounced?
    end

    def redirect_if_pending_profile
      redirect_to verify_account_url if current_user.decorate.pending_profile_requires_verification?
    end

    def extend_timeout_using_meta_refresh_for_select_paths
      return unless request.path == idv_doc_auth_step_path(step: :link_sent)
      max_10min_refreshes = Figaro.env.doc_auth_extend_timeout_by_minutes.to_i / 10
      return if max_10min_refreshes <= 0
      meta_refresh_count = flow_session[:meta_refresh_count].to_i
      return if meta_refresh_count >= max_10min_refreshes
      do_meta_refresh(meta_refresh_count)
    end

    def do_meta_refresh(meta_refresh_count)
      @meta_refresh = 10 * 60
      flow_session[:meta_refresh_count] = meta_refresh_count + 1
    end

    def flow_session
      user_session['idv/doc_auth_v2']
    end
  end
end
