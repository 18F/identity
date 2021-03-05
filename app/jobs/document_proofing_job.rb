class DocumentProofingJob < ApplicationJob
  queue_as :default

  def perform(args)
    result_id = args[:result_id]
    Idv::Proofer.document_job_class.handle(
      event: {
        encryption_key: args[:encryption_key],
        front_image_iv: args[:front_image_iv],
        back_image_iv: args[:back_image_iv],
        selfie_image_iv: args[:selfie_image_iv],
        front_image_url: args[:front_image_url],
        back_image_url: args[:back_image_url],
        selfie_image_url: args[:selfie_image_url],
        callback_url: args[:callback_url],
        liveness_checking_enabled: args[:liveness_checking_enabled],
        trace_id: args[:amzn_trace_id],
      },
      context: nil,
    ) do |result|
      document_result = result.to_h.fetch(:document_result, {})

      dcs = DocumentCaptureSession.new(result_id: result_id)

      dcs.store_doc_auth_result(
        result: document_result.except(:pii_from_doc),
        pii: document_result[:pii_from_doc],
      )
    end
  end
end
