Sentry.init do |config|
  config.dsn                   = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger    = [:active_support_logger, :http_logger]
  config.traces_sample_rate    = Rails.env.production? ? 0.2 : 0.0   # 20% in prod
  config.profiles_sample_rate  = Rails.env.production? ? 0.1 : 0.0
  config.send_default_pii      = false
  config.enabled_environments  = %w[production staging]

  config.before_send = lambda do |event, _hint|
    # Strip salary data from Sentry payloads — GDPR guard
    if event.request&.data.is_a?(Hash)
      event.request.data.delete("salary")
    end
    event
  end
end
