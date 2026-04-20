class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # ── Writer / Reader replica routing ─────────────────────────────────────────
  # All reads go to the replica; writes go to the primary.
  # Individual query objects can override with `.connected_to(role: :writing)`.
  connects_to database: { writing: :primary, reading: :primary_replica }
end
