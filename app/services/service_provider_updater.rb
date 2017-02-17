class ServiceProviderUpdater
  PROTECTED_ATTRIBUTES = [
    :id,
    :created_at,
    :updated_at,
  ].to_set.freeze

  def run
    dashboard_service_providers.each do |service_provider|
      update_local_caches(HashWithIndifferentAccess.new(service_provider))
    end
  end

  private

  def update_local_caches(service_provider)
    issuer = service_provider['issuer']
    update_cache(issuer, service_provider)
  end

  def update_cache(issuer, service_provider)
    if service_provider['active'] == true
      ServiceProvider.find_or_create_by!(issuer: issuer) do |sp|
        sp.attributes = cleaned_service_provider(service_provider)
      end
    else
      ServiceProvider.destroy_all(issuer: issuer, approved: false)
    end
  end

  def cleaned_service_provider(service_provider)
    service_provider.except(*PROTECTED_ATTRIBUTES)
  end

  def url
    Figaro.env.dashboard_url
  end

  def dashboard_service_providers
    body = dashboard_response.body
    return parse_service_providers(body) if dashboard_response.code == 200
    log_error "Failed to parse response from #{url}: #{body}"
    []
  rescue
    log_error "Failed to contact #{url}"
    []
  end

  def parse_service_providers(body)
    JSON.parse(body)
  end

  def dashboard_response
    @_dashboard_response ||= HTTParty.get(url)
  end

  def log_error(msg)
    Rails.logger.error msg
  end
end
