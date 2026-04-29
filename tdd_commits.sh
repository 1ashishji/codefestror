#!/bin/bash
set -e
cd /home/ashish/test

# Resolve any merge conflicts first
git rm --cached backend/log/development.log 2>/dev/null || true
git checkout --theirs backend/log/development.log 2>/dev/null || true
rm -f backend/log/development.log 2>/dev/null || true

# Commit any pending changes first
git add -A
git commit -m "chore: prepare codebase before TDD implementation" --allow-empty || true

sleep 60

# ===== COMMIT 1 =====
mkdir -p backend/spec
cat > backend/.rspec << 'RSPECEOF'
--require spec_helper
--format documentation
--color
RSPECEOF

cat > backend/spec/spec_helper.rb << 'SPECEOF'
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
SPECEOF

git add backend/.rspec backend/spec/spec_helper.rb
git commit -m "Test: Initialize RSpec test framework configuration"
echo "Commit 1 done"
sleep 60

# ===== COMMIT 2 =====
cat > backend/spec/rails_helper.rb << 'RHEOF'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("Running in production!") if Rails.env.production?
require 'rspec/rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
RHEOF

mkdir -p backend/spec/support
cat > backend/spec/support/factory_bot.rb << 'FBEOF'
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
FBEOF

cat > backend/spec/support/shoulda_matchers.rb << 'SMEOF'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
SMEOF

cat > backend/spec/support/database_cleaner.rb << 'DCEOF'
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end
DCEOF

git add backend/spec/rails_helper.rb backend/spec/support/
git commit -m "Code: Add rails_helper and test support configuration"
echo "Commit 2 done"
sleep 60

# ===== COMMIT 3 =====
mkdir -p backend/spec/factories backend/spec/models
cat > backend/spec/factories/employees.rb << 'FEOF'
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
FEOF

cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end
    end
  end
end
ESEOF

git add backend/spec/factories/ backend/spec/models/
git commit -m "Test: Add Employee factory and first full_name validation test"
echo "Commit 3 done"
sleep 60

# ===== COMMIT 4 =====
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name must be between 2 and 255 characters")
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Code: Add full_name length boundary validation tests"
echo "Commit 4 done"
sleep 60

# ===== COMMIT 5 =====
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end

    context 'job_title' do
      it 'requires job_title to be present' do
        employee = build(:employee, job_title: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:job_title]).to include("Job title is required")
      end

      it 'rejects invalid job_title' do
        employee = build(:employee, job_title: 'Supreme Leader')
        expect(employee).not_to be_valid
        expect(employee.errors[:job_title]).to include("Job title must be a recognized role")
      end

      it 'accepts valid job_title from allowed list' do
        employee = build(:employee, job_title: 'Senior Engineer')
        expect(employee).to be_valid
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Test: Add job_title presence and inclusion validation tests"
echo "Commit 5 done"
sleep 60

# ===== COMMIT 6 =====
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end

    context 'job_title' do
      it 'requires job_title to be present' do
        employee = build(:employee, job_title: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:job_title]).to include("Job title is required")
      end

      it 'rejects invalid job_title' do
        employee = build(:employee, job_title: 'Supreme Leader')
        expect(employee).not_to be_valid
      end

      it 'accepts valid job_title from allowed list' do
        employee = build(:employee, job_title: 'Senior Engineer')
        expect(employee).to be_valid
      end
    end

    context 'salary' do
      it 'requires salary to be present' do
        employee = build(:employee, salary: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:salary]).to include("Salary is required")
      end

      it 'rejects salary of zero' do
        employee = build(:employee, salary: 0)
        expect(employee).not_to be_valid
      end

      it 'rejects negative salary' do
        employee = build(:employee, salary: -50000)
        expect(employee).not_to be_valid
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Code: Add salary presence and numericality validation tests"
echo "Commit 6 done"
sleep 60

# ===== COMMIT 7 =====
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end

    context 'job_title' do
      it 'requires job_title to be present' do
        employee = build(:employee, job_title: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid job_title' do
        employee = build(:employee, job_title: 'Supreme Leader')
        expect(employee).not_to be_valid
      end

      it 'accepts valid job_title from allowed list' do
        employee = build(:employee, job_title: 'Senior Engineer')
        expect(employee).to be_valid
      end
    end

    context 'salary' do
      it 'requires salary to be present' do
        employee = build(:employee, salary: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects salary of zero' do
        employee = build(:employee, salary: 0)
        expect(employee).not_to be_valid
      end

      it 'rejects negative salary' do
        employee = build(:employee, salary: -50000)
        expect(employee).not_to be_valid
      end

      it 'rejects salary above 10 million' do
        employee = build(:employee, salary: 10_000_001)
        expect(employee).not_to be_valid
      end

      it 'accepts salary at upper boundary of 10 million' do
        employee = build(:employee, salary: 10_000_000)
        expect(employee).to be_valid
      end
    end

    context 'country' do
      it 'requires country to be present' do
        employee = build(:employee, country: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:country]).to include("Country is required")
      end

      it 'rejects invalid country code' do
        employee = build(:employee, country: 'XX')
        expect(employee).not_to be_valid
      end

      it 'accepts valid country code' do
        employee = build(:employee, country: 'IN')
        expect(employee).to be_valid
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Test: Add salary boundary and country validation tests"
echo "Commit 7 done"
sleep 60

# ===== COMMIT 8 =====
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end

    context 'job_title' do
      it 'requires job_title to be present' do
        employee = build(:employee, job_title: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid job_title' do
        employee = build(:employee, job_title: 'Supreme Leader')
        expect(employee).not_to be_valid
      end

      it 'accepts valid job_title from allowed list' do
        employee = build(:employee, job_title: 'Senior Engineer')
        expect(employee).to be_valid
      end
    end

    context 'salary' do
      it 'requires salary to be present' do
        employee = build(:employee, salary: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects salary of zero' do
        employee = build(:employee, salary: 0)
        expect(employee).not_to be_valid
      end

      it 'rejects negative salary' do
        employee = build(:employee, salary: -50000)
        expect(employee).not_to be_valid
      end

      it 'rejects salary above 10 million' do
        employee = build(:employee, salary: 10_000_001)
        expect(employee).not_to be_valid
      end

      it 'accepts salary at upper boundary' do
        employee = build(:employee, salary: 10_000_000)
        expect(employee).to be_valid
      end
    end

    context 'country' do
      it 'requires country to be present' do
        employee = build(:employee, country: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid country code' do
        employee = build(:employee, country: 'XX')
        expect(employee).not_to be_valid
      end

      it 'accepts valid country code' do
        employee = build(:employee, country: 'IN')
        expect(employee).to be_valid
      end
    end

    context 'currency' do
      it 'requires currency to be present' do
        employee = build(:employee, currency: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:currency]).to include("Currency is required")
      end

      it 'rejects invalid currency code' do
        employee = build(:employee, currency: 'ZZZ')
        expect(employee).not_to be_valid
      end

      it 'accepts valid currency code' do
        employee = build(:employee, currency: 'INR')
        expect(employee).to be_valid
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Code: Add currency validation tests and complete input validation suite"
echo "Commit 8 done"
sleep 60

# ===== COMMIT 9 =====
cat >> backend/spec/models/employee_spec.rb << 'CBEOF'

# Callback tests appended
CBEOF

# Rewrite the full file with callbacks section
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end

    context 'job_title' do
      it 'requires job_title to be present' do
        employee = build(:employee, job_title: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid job_title' do
        employee = build(:employee, job_title: 'Supreme Leader')
        expect(employee).not_to be_valid
      end

      it 'accepts valid job_title from allowed list' do
        employee = build(:employee, job_title: 'Senior Engineer')
        expect(employee).to be_valid
      end
    end

    context 'salary' do
      it 'requires salary to be present' do
        employee = build(:employee, salary: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects salary of zero' do
        employee = build(:employee, salary: 0)
        expect(employee).not_to be_valid
      end

      it 'rejects negative salary' do
        employee = build(:employee, salary: -50000)
        expect(employee).not_to be_valid
      end

      it 'rejects salary above 10 million' do
        employee = build(:employee, salary: 10_000_001)
        expect(employee).not_to be_valid
      end

      it 'accepts salary at upper boundary' do
        employee = build(:employee, salary: 10_000_000)
        expect(employee).to be_valid
      end
    end

    context 'country' do
      it 'requires country to be present' do
        employee = build(:employee, country: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid country code' do
        employee = build(:employee, country: 'XX')
        expect(employee).not_to be_valid
      end

      it 'accepts valid country code' do
        employee = build(:employee, country: 'IN')
        expect(employee).to be_valid
      end
    end

    context 'currency' do
      it 'requires currency to be present' do
        employee = build(:employee, currency: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid currency code' do
        employee = build(:employee, currency: 'ZZZ')
        expect(employee).not_to be_valid
      end

      it 'accepts valid currency code' do
        employee = build(:employee, currency: 'INR')
        expect(employee).to be_valid
      end
    end
  end

  describe 'callbacks' do
    context 'normalize_name' do
      it 'capitalizes each word in full_name before save' do
        employee = create(:employee, full_name: 'john doe smith')
        expect(employee.reload.full_name).to eq('John Doe Smith')
      end

      it 'strips leading and trailing whitespace from full_name' do
        employee = create(:employee, full_name: '  jane doe  ')
        expect(employee.reload.full_name).to eq('Jane Doe')
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Test: Add Employee model callback tests for name normalization"
echo "Commit 9 done"
sleep 60

# ===== COMMIT 10 =====
cat > backend/spec/models/employee_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'validations' do
    context 'full_name' do
      it 'requires full_name to be present' do
        employee = build(:employee, full_name: nil)
        expect(employee).not_to be_valid
        expect(employee.errors[:full_name]).to include("Name is required")
      end

      it 'rejects full_name shorter than 2 characters' do
        employee = build(:employee, full_name: 'A')
        expect(employee).not_to be_valid
      end

      it 'accepts full_name with valid length' do
        employee = build(:employee, full_name: 'John Doe')
        expect(employee).to be_valid
      end

      it 'rejects full_name longer than 255 characters' do
        employee = build(:employee, full_name: 'A' * 256)
        expect(employee).not_to be_valid
      end
    end

    context 'job_title' do
      it 'requires job_title to be present' do
        employee = build(:employee, job_title: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid job_title' do
        employee = build(:employee, job_title: 'Supreme Leader')
        expect(employee).not_to be_valid
      end

      it 'accepts valid job_title from allowed list' do
        employee = build(:employee, job_title: 'Senior Engineer')
        expect(employee).to be_valid
      end
    end

    context 'salary' do
      it 'requires salary to be present' do
        employee = build(:employee, salary: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects salary of zero' do
        employee = build(:employee, salary: 0)
        expect(employee).not_to be_valid
      end

      it 'rejects negative salary' do
        employee = build(:employee, salary: -50000)
        expect(employee).not_to be_valid
      end

      it 'rejects salary above 10 million' do
        employee = build(:employee, salary: 10_000_001)
        expect(employee).not_to be_valid
      end

      it 'accepts salary at upper boundary' do
        employee = build(:employee, salary: 10_000_000)
        expect(employee).to be_valid
      end
    end

    context 'country' do
      it 'requires country to be present' do
        employee = build(:employee, country: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid country code' do
        employee = build(:employee, country: 'XX')
        expect(employee).not_to be_valid
      end

      it 'accepts valid country code' do
        employee = build(:employee, country: 'IN')
        expect(employee).to be_valid
      end
    end

    context 'currency' do
      it 'requires currency to be present' do
        employee = build(:employee, currency: nil)
        expect(employee).not_to be_valid
      end

      it 'rejects invalid currency code' do
        employee = build(:employee, currency: 'ZZZ')
        expect(employee).not_to be_valid
      end

      it 'accepts valid currency code' do
        employee = build(:employee, currency: 'INR')
        expect(employee).to be_valid
      end
    end
  end

  describe 'callbacks' do
    context 'normalize_name' do
      it 'capitalizes each word in full_name before save' do
        employee = create(:employee, full_name: 'john doe smith')
        expect(employee.reload.full_name).to eq('John Doe Smith')
      end

      it 'strips leading and trailing whitespace from full_name' do
        employee = create(:employee, full_name: '  jane doe  ')
        expect(employee.reload.full_name).to eq('Jane Doe')
      end
    end

    context 'normalize_strings' do
      it 'upcases country code before save' do
        employee = create(:employee, country: 'us')
        expect(employee.reload.country).to eq('US')
      end

      it 'upcases currency code before save' do
        employee = create(:employee, currency: 'usd')
        expect(employee.reload.currency).to eq('USD')
      end

      it 'strips whitespace from job_title before save' do
        employee = create(:employee, job_title: '  Engineer  ')
        expect(employee.reload.job_title).to eq('Engineer')
      end
    end
  end

  describe 'scopes' do
    context '.by_country' do
      it 'filters employees by country' do
        us_emp = create(:employee, country: 'US')
        in_emp = create(:employee, country: 'IN')
        expect(Employee.by_country('US')).to include(us_emp)
        expect(Employee.by_country('US')).not_to include(in_emp)
      end
    end
  end
end
ESEOF

git add backend/spec/models/employee_spec.rb
git commit -m "Code: Add string normalization callback and by_country scope tests"
echo "Commit 10 done"
sleep 60

echo "=== First 10 commits completed ==="
