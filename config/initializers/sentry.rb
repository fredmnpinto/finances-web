Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.send_default_pii = true
  config.environment = Rails.env
  config.enabled_environments = []
  config.background_worker_threads = 0
  config.debug = true
end
