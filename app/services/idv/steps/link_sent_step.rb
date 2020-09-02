module Idv
  module Steps
    class LinkSentStep < DocAuthBaseStep
      def call
        if FeatureManagement.document_capture_step_enabled?
          validate_document_capture_session_results
        else
          validate_doc_auth_results
        end
      end

      private

      def validate_document_capture_session_results
        result = document_capture_session&.load_result
        mark_steps_complete if result.present? && result.success?
      end

      def validate_doc_auth_results
        return render_step_incomplete_error unless take_photo_with_phone_successful?

        # The doc capture flow will have fetched the results already. We need
        # to fetch them again here to add the PII to this session
        get_results_response = fetch_doc_auth_results
        if get_results_response.success?
          handle_document_verification_success(get_results_response)
        else
          handle_document_verification_failure(get_results_response)
        end
      end

      def fetch_doc_auth_results
        DocAuth::Client.client.get_results(
          instance_id: doc_capture_record.acuant_token,
        )
      end

      def handle_document_verification_success(get_results_response)
        save_proofing_components
        extract_pii_from_doc(get_results_response)
        mark_steps_complete
      end

      def handle_document_verification_failure(get_results_response)
        mark_step_incomplete(:send_link)
        failure(get_results_response.first_error_message, get_results_response.to_h)
      end

      def render_step_incomplete_error
        failure(I18n.t('errors.doc_auth.phone_step_incomplete'))
      end

      def take_photo_with_phone_successful?
        doc_capture_record&.acuant_token.present?
      end

      def doc_capture_record
        @doc_capture_record ||= DocCapture.find_by(user_id: user_id)
      end

      def mark_steps_complete
        %i[send_link link_sent email_sent mobile_front_image mobile_back_image front_image
           back_image selfie document_capture].each do |step|
          mark_step_complete(step)
        end
      end
    end
  end
end
