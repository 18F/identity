# frozen_string_literal: true

module DocAuth
  module LexisNexis
    module Responses
      class TrueIdResponse < LexisNexisResponse
        def initialize(http_response, liveness_checking_enabled)
          @liveness_checking_enabled = liveness_checking_enabled

          super http_response
        end

        def successful_result?
          transaction_status_passed? &&
            product_status_passed? &&
            doc_auth_result_passed?
        end

        def error_messages
          return {} if successful_result?

          response_error_info = {
            ConversationId: conversation_id,
            Reference: reference,
            Product: 'TrueID',
            TransactionReasonCode: transaction_reason_code,
            DocAuthResult: doc_auth_result,
            Alerts: parse_alerts,
            PortraitMatchResults: true_id_product[:PORTRAIT_MATCH_RESULT],
          }

          ErrorGenerator.generate_trueid_errors(response_error_info, liveness_checking_enabled)
        end

        def extra_attributes
          true_id_product[:AUTHENTICATION_RESULT].reject do |k, _v|
            PII_DETAILS.include? k
          end
        end

        def pii_from_doc
          true_id_product[:AUTHENTICATION_RESULT].select do |k, _v|
            PII_DETAILS.include? k
          end
        end

        private

        def product_status_passed?
          product_status == 'pass'
        end

        def doc_auth_result_passed?
          doc_auth_result == 'Passed'
        end

        def doc_auth_result
          true_id_product.dig(:AUTHENTICATION_RESULT, :DocAuthResult)
        end

        def product_status
          true_id_product.dig(:ProductStatus)
        end

        def true_id_product
          products[:TrueID]
        end

        def parse_alerts
          new_alerts = []
          all_alerts = true_id_product[:AUTHENTICATION_RESULT].select do |key|
            key.start_with?('Alert_')
          end

          # Make the assumption that every alert will have an *_AlertName associated with it
          alert_names = all_alerts.select { |key| key.end_with?('_AlertName') }
          alert_names.each do |alert_name, _v|
            alert_prefix = alert_name.scan(/Alert_\d{1,2}_/).first
            new_alerts.push(combine_alert_data(all_alerts, alert_prefix))
          end

          new_alerts
        end

        def combine_alert_data(all_alerts, alert_name)
          new_alert_data = {}
          # Get the set of Alerts that are all the same number (e.g. Alert_11)
          alert_set = all_alerts.select { |key| key.match?(alert_name) }

          alert_set.each do |key, value|
            new_alert_data[:alert] = alert_name.delete_suffix('_')
            new_alert_data[:name] = value if key.end_with?('_AlertName')
            new_alert_data[:result] = value if key.end_with?('_AuthenticationResult')
            new_alert_data[:region] = value if key.end_with?('_Regions')
          end

          new_alert_data
        end

        def detail_groups
          %w[
            AUTHENTICATION_RESULT
            IDAUTH_FIELD_DATA
            IDAUTH_FIELD_NATIVE_DATA
            IMAGE_METRICS_RESULT
            PORTRAIT_MATCH_RESULT
          ].freeze
        end
      end
    end
  end
end