require "faker"

EMPLOYEE_COUNT = Integer(ENV.fetch("EMPLOYEE_SEED_COUNT", 10_000))
BATCH_SIZE = Integer(ENV.fetch("EMPLOYEE_SEED_BATCH_SIZE", 1_000))

job_titles = Employee::ALLOWED_JOB_TITLES
countries = Employee::ALLOWED_COUNTRIES
currencies = Employee::ALLOWED_CURRENCIES
now = Time.current

puts "Seeding #{EMPLOYEE_COUNT} employees..."

Employee.delete_all if ENV["RESET_EMPLOYEES"] == "1"

created = 0

EMPLOYEE_COUNT.times.each_slice(BATCH_SIZE) do |slice|
  rows = slice.map do
    {
      full_name: Faker::Name.name,
      job_title: job_titles.sample,
      country: countries.sample,
      salary: rand(35_000.00..450_000.00).round(2),
      currency: currencies.sample,
      department_id: rand(1..25),
      lock_version: 0,
      created_at: now,
      updated_at: now
    }
  end

  Employee.insert_all!(rows)
  created += rows.size
  puts "Seeded #{created}/#{EMPLOYEE_COUNT} employees"
end

puts "Done. Employees in database: #{Employee.count}"
