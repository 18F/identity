class SessionsNew
  def initialize(modal: nil)
    @modal = modal
  end

  def title
    I18n.t('idv.titles.session.basic')
  end

  def mock_vendor_partial
    if idv_vendor.pick == :mock
      'verify/sessions/no_pii_warning'
    else
      'shared/null'
    end
  end

  def modal_type
    modal
  end

  def modal_partial
    if modal.present?
      'shared/modal_verification'
    else
      'shared/null'
    end
  end

  private

  attr_reader :modal

  def idv_vendor
    @_idv_vendor ||= Idv::Vendor.new
  end
end
