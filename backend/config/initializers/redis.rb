# ─────────────────────────────────────────────────────────────────────────────
# Redis connection pool initializer
# ─────────────────────────────────────────────────────────────────────────────

REDIS_POOL = ConnectionPool.new(size: ENV.fetch("REDIS_POOL_SIZE", 10).to_i, timeout: 5) do
  Redis.new(
    url:            ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    reconnect_attempts: 3
  )
end

# Convenience wrapper — REDIS_POOL.with { |r| r.get("key") }
# Sidekiq also picks up REDIS_URL automatically.
