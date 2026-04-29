FactoryBot.define do
  factory :employee do
    full_name   { "John Doe" }
    job_title   { "Engineer" }
    country     { "US" }
    salary      { 75000.00 }
    currency    { "USD" }
    department_id { 1 }
  end
end
