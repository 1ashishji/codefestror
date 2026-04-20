require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module SalaryManagement
  class Application < Rails::Application
    config.load_defaults 7.2

    # API-only — no cookies, sessions, or asset pipeline
    config.api_only = true

    # Timezone
    config.time_zone = "UTC"

    # ── Caching (Redis) ─────────────────────────────────────────────────────────
    config.cache_store = :redis_cache_store, {
      url:             ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
      connect_timeout: 30,
      read_timeout:    0.2,
      write_timeout:   0.2,
      reconnect_attempts: 1,
      error_handler: ->(method:, returning:, exception:) {
        Sentry.capture_exception(exception, level: "warning",
          tags: { method: method, returning: returning })
      }
    }

    # ── Background Jobs ─────────────────────────────────────────────────────────
    config.active_job.queue_adapter = :sidekiq

    # ── Logging ─────────────────────────────────────────────────────────────────
    config.log_level = :info

    # ── Autoload Paths ──────────────────────────────────────────────────────────
    config.autoload_paths += %W[
      #{root}/app/services
      #{root}/app/queries
      #{root}/app/serializers
    ]

    # ── Generators ──────────────────────────────────────────────────────────────
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
    end
  end
end
