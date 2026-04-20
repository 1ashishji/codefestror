# ─────────────────────────────────────────────────────────────────────────────
# Employee Model
# ─────────────────────────────────────────────────────────────────────────────
class Employee < ApplicationRecord
  # ── Audit ──────────────────────────────────────────────────────────────────
  attr_accessor :current_ip

  has_paper_trail meta: { current_ip: :current_ip }

  # ── Optimistic Locking ─────────────────────────────────────────────────────
  # lock_version column handled natively by ActiveRecord.
  # Raises ActiveRecord::StaleObjectError on concurrent edits.

  # ── Enums ──────────────────────────────────────────────────────────────────
  ALLOWED_CURRENCIES = %w[USD INR SGD GBP EUR JPY AUD CAD].freeze
  ALLOWED_COUNTRIES  = %w[
    US IN SG GB DE FR JP AU CA NZ ZA BR MX NG KE PH ID MY TH VN
    AE SA QA KW BH OM PK LK BD NP MM
  ].freeze

  ALLOWED_JOB_TITLES = [
    "Junior Engineer", "Engineer", "Senior Engineer", "Staff Engineer",
    "Principal Engineer", "Engineering Manager", "Director of Engineering",
    "VP Engineering", "CTO",
    "Junior Analyst", "Analyst", "Senior Analyst", "Lead Analyst",
    "Data Scientist", "Senior Data Scientist", "ML Engineer",
    "Product Manager", "Senior Product Manager", "Director of Product",
    "Designer", "Senior Designer", "UX Lead",
    "Junior Developer", "Developer", "Senior Developer",
    "DevOps Engineer", "Senior DevOps Engineer",
    "QA Engineer", "Senior QA Engineer",
    "HR Specialist", "HR Manager", "Recruiter",
    "Finance Analyst", "Finance Manager", "CFO"
  ].freeze

  # ── Validations ────────────────────────────────────────────────────────────
  validates :full_name,
    presence:  { message: "Name is required" },
    length:    { in: 2..255, message: "Name must be between 2 and 255 characters" }

  validates :job_title,
    presence:  { message: "Job title is required" },
    inclusion: { in: ALLOWED_JOB_TITLES, message: "Job title must be a recognized role" }

  validates :country,
    presence:  { message: "Country is required" },
    inclusion: { in: ALLOWED_COUNTRIES, message: "Country must be a valid ISO 3166-1 alpha-2 code (e.g. IN, US, SG)" }

  validates :salary,
    presence:    { message: "Salary is required" },
    numericality: {
      greater_than:             0,
      less_than_or_equal_to:    10_000_000,
      message:                  "Salary must be a positive number up to 10,000,000"
    }

  validates :currency,
    presence:  { message: "Currency is required" },
    inclusion: { in: ALLOWED_CURRENCIES, message: "Currency must be one of #{ALLOWED_CURRENCIES.join(', ')}" }

  validates :department_id,
    numericality: { only_integer: true, allow_nil: true, message: "Department ID must be a valid integer" }

  validates :lock_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # ── Callbacks ──────────────────────────────────────────────────────────────
  before_save :normalize_name
  before_save :normalize_strings
  before_save :touch_country_cache, if: :salary_changed?

  # ── Scopes ─────────────────────────────────────────────────────────────────
  scope :by_country,    ->(c)    { where(country: c) }
  scope :by_title,      ->(t)    { where(job_title: t) }
  scope :by_department, ->(d)    { where(department_id: d) }
  scope :salary_above,  ->(amt)  { where("salary > ?", amt) }
  scope :salary_below,  ->(amt)  { where("salary < ?", amt) }
  scope :page_after,    ->(cursor, limit = 50) {
    where("id > ?", cursor.to_i).order(:id).limit(limit)
  }

  # FULLTEXT search — uses the FULLTEXT index on full_name
  scope :fulltext_search, ->(query) {
    where("MATCH(full_name) AGAINST(? IN BOOLEAN MODE)", "#{sanitize_sql_like(query)}*")
      .order(Arel.sql("MATCH(full_name) AGAINST('#{sanitize_sql_like(query)}*' IN BOOLEAN MODE) DESC"))
  }

  # ── Cache Key Helpers ──────────────────────────────────────────────────────
  def self.country_cache_key(country)
    "salary_insights:country:#{country}"
  end

  def self.global_cache_key
    "salary_insights:global"
  end

  private

  def normalize_name
    self.full_name = full_name.strip.split.map(&:capitalize).join(" ") if full_name.present?
  end

  def normalize_strings
    self.job_title = job_title.strip   if job_title.present?
    self.country   = country.upcase    if country.present?
    self.currency  = currency.upcase   if currency.present?
  end

  def touch_country_cache
    # Invalidate redis insights for this employee's country on next request
    REDIS_POOL.with { |r| r.del(self.class.country_cache_key(country)) }
    REDIS_POOL.with { |r| r.del(self.class.global_cache_key) }
  end
end
