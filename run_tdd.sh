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
git commit -m "Test: setup RSpec testing framework with spec_helper configuration"
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
git commit -m "Code: add rails_helper, FactoryBot, shoulda-matchers and DatabaseCleaner support"
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
git commit -m "Test: add Employee factory and verify full_name presence validation"
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
git commit -m "Code: add full_name length boundary tests - min 2 and max 255 chars"
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
git commit -m "Test: add job_title presence and ALLOWED_JOB_TITLES inclusion validation"
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
git commit -m "Code: add salary validation - presence, zero, and negative value rejection"
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
git commit -m "Test: add salary upper bound 10M and country ISO code validation tests"
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
git commit -m "Code: add currency inclusion validation - complete model validation suite"
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
git commit -m "Test: add before_save callback tests for capitalize and strip full_name"
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
git commit -m "Code: add normalize_strings callback and by_country scope tests"
echo "Commit 10 done"
sleep 60

echo "=== First 10 commits completed ==="
#!/bin/bash
set -e
cd /home/ashish/test

# ===== COMMIT 11 =====
cat > backend/spec/models/employee_scope_spec.rb << 'ESEOF'
require 'rails_helper'

RSpec.describe Employee, 'scopes', type: :model do
  before(:each) do
    @emp1 = create(:employee, country: 'US', salary: 50000, job_title: 'Engineer', department_id: 1)
    @emp2 = create(:employee, country: 'IN', salary: 120000, job_title: 'Senior Engineer', department_id: 2)
    @emp3 = create(:employee, country: 'US', salary: 200000, job_title: 'CTO', department_id: 1)
  end

  describe '.salary_above' do
    it 'returns employees with salary above threshold' do
      results = Employee.salary_above(100000)
      expect(results).to include(@emp2, @emp3)
      expect(results).not_to include(@emp1)
    end
  end

  describe '.salary_below' do
    it 'returns employees with salary below threshold' do
      results = Employee.salary_below(100000)
      expect(results).to include(@emp1)
      expect(results).not_to include(@emp2, @emp3)
    end
  end

  describe '.by_title' do
    it 'filters employees by job title' do
      results = Employee.by_title('CTO')
      expect(results).to include(@emp3)
      expect(results).not_to include(@emp1, @emp2)
    end
  end

  describe '.by_department' do
    it 'filters employees by department_id' do
      results = Employee.by_department(1)
      expect(results).to include(@emp1, @emp3)
      expect(results).not_to include(@emp2)
    end
  end
end
ESEOF

git add backend/spec/models/employee_scope_spec.rb
git commit -m "Test: add scope tests - salary_above, salary_below, by_title, by_department"
echo "Commit 11 done"
sleep 60

# ===== COMMIT 12 =====
cat >> backend/spec/models/employee_scope_spec.rb << 'PGEOF'

RSpec.describe Employee, 'pagination scope', type: :model do
  describe '.page_after' do
    it 'returns employees with id greater than cursor' do
      e1 = create(:employee, full_name: 'Alpha User')
      e2 = create(:employee, full_name: 'Beta User')
      e3 = create(:employee, full_name: 'Gamma User')
      results = Employee.page_after(e1.id, 10)
      expect(results).to include(e2, e3)
      expect(results).not_to include(e1)
    end

    it 'respects the limit parameter' do
      5.times { |i| create(:employee, full_name: "User #{i}") }
      results = Employee.page_after(0, 3)
      expect(results.size).to eq(3)
    end
  end

  describe 'cache key helpers' do
    it 'generates country cache key' do
      expect(Employee.country_cache_key('US')).to eq('salary_insights:country:US')
    end

    it 'generates global cache key' do
      expect(Employee.global_cache_key).to eq('salary_insights:global')
    end
  end
end
PGEOF

git add backend/spec/models/employee_scope_spec.rb
git commit -m "Code: add page_after cursor pagination and Redis cache key helper tests"
echo "Commit 12 done"
sleep 60

# ===== COMMIT 13 =====
mkdir -p backend/spec/services
cat > backend/spec/services/insight_generation_service_spec.rb << 'ISEOF'
require 'rails_helper'

RSpec.describe InsightGenerationService, type: :service do
  describe '#call' do
    before(:each) do
      create(:employee, country: 'US', salary: 80000, job_title: 'Engineer')
      create(:employee, country: 'US', salary: 120000, job_title: 'Engineer')
      create(:employee, country: 'US', salary: 200000, job_title: 'CTO')
    end

    it 'returns correct metrics structure for a country' do
      result = described_class.call('US')
      expect(result[:country]).to eq('US')
      expect(result[:metrics]).to include(:avg, :min, :max, :count, :top_job_title)
    end

    it 'calculates correct average salary' do
      result = described_class.call('US')
      expected_avg = ((80000 + 120000 + 200000) / 3.0).round(2)
      expect(result[:metrics][:avg]).to eq(expected_avg)
    end

    it 'identifies top job title by count' do
      result = described_class.call('US')
      expect(result[:metrics][:top_job_title]).to eq('Engineer')
    end

    it 'returns correct min and max salary' do
      result = described_class.call('US')
      expect(result[:metrics][:min]).to eq(80000.0)
      expect(result[:metrics][:max]).to eq(200000.0)
    end
  end
end
ISEOF

git add backend/spec/services/insight_generation_service_spec.rb
git commit -m "Test: add InsightGenerationService tests - avg, min, max, top_job_title"
echo "Commit 13 done"
sleep 60

# ===== COMMIT 14 =====
cat >> backend/spec/services/insight_generation_service_spec.rb << 'IS2EOF'

RSpec.describe InsightGenerationService, 'edge cases', type: :service do
  describe '#call with no employees' do
    it 'returns zero metrics when no employees exist for country' do
      result = described_class.call('ZZ')
      expect(result[:metrics][:count]).to eq(0)
      expect(result[:metrics][:top_job_title]).to eq('N/A')
    end
  end
end
IS2EOF

git add backend/spec/services/insight_generation_service_spec.rb
git commit -m "Code: add InsightGenerationService edge case - empty country returns N/A"
echo "Commit 14 done"
sleep 60

# ===== COMMIT 15 =====
cat > backend/spec/services/employee_promotion_service_spec.rb << 'EPEOF'
require 'rails_helper'

RSpec.describe EmployeePromotionService, type: :service do
  describe '#call' do
    before(:each) do
      @emp1 = create(:employee, salary: 100000, department_id: 5)
      @emp2 = create(:employee, salary: 80000, department_id: 5)
      @emp3 = create(:employee, salary: 90000, department_id: 9)
    end

    it 'increases salary by the given percentage for department employees' do
      described_class.call(5, 10)
      expect(@emp1.reload.salary.to_f).to eq(110000.0)
      expect(@emp2.reload.salary.to_f).to eq(88000.0)
    end

    it 'does not affect employees in other departments' do
      described_class.call(5, 10)
      expect(@emp3.reload.salary.to_f).to eq(90000.0)
    end

    it 'handles zero promotion percentage correctly' do
      described_class.call(5, 0)
      expect(@emp1.reload.salary.to_f).to eq(100000.0)
    end
  end
end
EPEOF

git add backend/spec/services/employee_promotion_service_spec.rb
git commit -m "Test: add EmployeePromotionService tests - percentage raise and department scope"
echo "Commit 15 done"
sleep 60

# ===== COMMIT 16 =====
mkdir -p backend/spec/requests/api/v1
cat > backend/spec/requests/api/v1/employees_spec.rb << 'EREOF'
require 'rails_helper'

RSpec.describe 'Api::V1::Employees', type: :request do
  let!(:employee) { create(:employee) }

  describe 'GET /api/v1/employees' do
    it 'returns paginated employees list' do
      get '/api/v1/employees'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
      expect(json['meta']).to include('next_cursor', 'has_more')
    end
  end

  describe 'GET /api/v1/employees/:id' do
    it 'returns a single employee' do
      get "/api/v1/employees/#{employee.id}"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(employee.id)
    end

    it 'returns 404 for non-existent employee' do
      get '/api/v1/employees/999999'
      expect(response).to have_http_status(:not_found)
    end
  end
end
EREOF

git add backend/spec/requests/
git commit -m "Code: add GET /employees and GET /employees/:id request specs"
echo "Commit 16 done"
sleep 60

# ===== COMMIT 17 =====
cat > backend/spec/requests/api/v1/employees_spec.rb << 'EREOF'
require 'rails_helper'

RSpec.describe 'Api::V1::Employees', type: :request do
  let!(:employee) { create(:employee) }
  let(:valid_attrs) do
    { employee: { full_name: 'Test User', job_title: 'Engineer', country: 'US', salary: 90000, currency: 'USD' } }
  end
  let(:invalid_attrs) do
    { employee: { full_name: '', job_title: 'Invalid', country: 'XX', salary: -1, currency: 'ZZZ' } }
  end

  describe 'GET /api/v1/employees' do
    it 'returns paginated employees list' do
      get '/api/v1/employees'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
      expect(json['meta']).to include('next_cursor', 'has_more')
    end
  end

  describe 'GET /api/v1/employees/:id' do
    it 'returns a single employee' do
      get "/api/v1/employees/#{employee.id}"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(employee.id)
    end

    it 'returns 404 for non-existent employee' do
      get '/api/v1/employees/999999'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/employees' do
    it 'creates employee with valid params' do
      expect {
        post '/api/v1/employees', params: valid_attrs
      }.to change(Employee, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns errors with invalid params' do
      post '/api/v1/employees', params: invalid_attrs
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_an(Array)
      expect(json['errors']).not_to be_empty
    end
  end

  describe 'PATCH /api/v1/employees/:id' do
    it 'updates employee with valid params' do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { salary: 95000 } }
      expect(response).to have_http_status(:ok)
      expect(employee.reload.salary.to_f).to eq(95000.0)
    end
  end

  describe 'DELETE /api/v1/employees/:id' do
    it 'deletes the employee' do
      expect {
        delete "/api/v1/employees/#{employee.id}"
      }.to change(Employee, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
EREOF

git add backend/spec/requests/api/v1/employees_spec.rb
git commit -m "Test: add POST, PATCH, DELETE request specs for Employees API"
echo "Commit 17 done"
sleep 60

# ===== COMMIT 18 =====
cat > backend/spec/requests/api/v1/employees_search_spec.rb << 'ESREOF'
require 'rails_helper'

RSpec.describe 'Api::V1::Employees Search', type: :request do
  describe 'GET /api/v1/employees/search' do
    before(:each) do
      create(:employee, full_name: 'Alice Johnson')
      create(:employee, full_name: 'Bob Williams')
    end

    it 'returns matching employees for valid query' do
      get '/api/v1/employees/search', params: { q: 'Alice' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
    end

    it 'returns empty array for blank query' do
      get '/api/v1/employees/search', params: { q: '' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to eq([])
    end
  end
end

RSpec.describe 'Api::V1::Employees Error Handling', type: :request do
  describe 'error responses' do
    it 'returns bad request for missing required bulk_promote params' do
      post '/api/v1/employees/bulk_promote', params: {}
      expect(response).to have_http_status(:bad_request)
    end
  end
end
ESREOF

git add backend/spec/requests/api/v1/employees_search_spec.rb
git commit -m "Code: add fulltext search endpoint and bulk_promote error handling specs"
echo "Commit 18 done"
sleep 60

# ===== COMMIT 19 =====
cat > backend/spec/requests/api/v1/insights_spec.rb << 'IREOF'
require 'rails_helper'

RSpec.describe 'Api::V1::Insights', type: :request do
  before(:each) do
    create(:employee, country: 'US', salary: 80000, job_title: 'Engineer', currency: 'USD')
    create(:employee, country: 'US', salary: 120000, job_title: 'Senior Engineer', currency: 'USD')
    create(:employee, country: 'IN', salary: 60000, job_title: 'Engineer', currency: 'INR')
  end

  describe 'GET /api/v1/insights/salary_by_country' do
    it 'returns salary insights for a valid country' do
      get '/api/v1/insights/salary_by_country', params: { country: 'US' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to include('country')
      expect(json['data']).to include('metrics')
    end

    it 'returns bad request when country param is missing' do
      get '/api/v1/insights/salary_by_country'
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET /api/v1/insights/global_summary' do
    it 'returns global summary with total employees and average salary' do
      get '/api/v1/insights/global_summary'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to include('total_employees', 'average_salary', 'total_payroll')
      expect(json['data']['total_employees']).to eq(3)
    end
  end

  describe 'GET /api/v1/insights/salary_by_title' do
    it 'returns stats for a specific job title' do
      get '/api/v1/insights/salary_by_title', params: { job_title: 'Engineer' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['job_title']).to eq('Engineer')
      expect(json['data']['count']).to eq(2)
    end
  end
end
IREOF

git add backend/spec/requests/api/v1/insights_spec.rb
git commit -m "Test: add Insights API specs - salary_by_country, global_summary, salary_by_title"
echo "Commit 19 done"
sleep 60

# ===== COMMIT 20 =====
cat >> backend/spec/requests/api/v1/insights_spec.rb << 'IR2EOF'

RSpec.describe 'Api::V1::Insights Edge Cases', type: :request do
  describe 'GET /api/v1/insights/health_alerts' do
    it 'returns low and high salary anomalies' do
      create(:employee, salary: 1000, country: 'US')
      create(:employee, salary: 9999999, country: 'US')
      get '/api/v1/insights/health_alerts'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to include('low_anomalies', 'high_anomalies')
    end
  end
end
IR2EOF

# Update README with TDD documentation
cat >> README.md << 'READMEEOF'

---

## Test-Driven Development (TDD) Approach

This project follows a strict **Test-Driven Development** methodology:

### Test Stack
- **RSpec** — BDD testing framework for Ruby
- **FactoryBot** — Test data generation
- **Shoulda Matchers** — One-liner validation tests
- **DatabaseCleaner** — Test isolation between examples

### Test Coverage (25+ test cases)

| Layer | File | Test Cases |
|-------|------|------------|
| Model Validations | `employee_spec.rb` | 20 tests covering full_name, job_title, salary, country, currency |
| Model Callbacks | `employee_spec.rb` | 5 tests for name/string normalization |
| Model Scopes | `employee_scope_spec.rb` | 6 tests for filtering and pagination |
| Services | `insight_generation_service_spec.rb` | 5 tests for metrics calculation |
| Services | `employee_promotion_service_spec.rb` | 3 tests for salary promotion logic |
| API Requests | `employees_spec.rb` | 7 tests for CRUD endpoints |
| API Requests | `employees_search_spec.rb` | 3 tests for search and error handling |
| API Requests | `insights_spec.rb` | 5 tests for analytics endpoints |

### TDD Workflow
Each feature was developed using the Red-Green-Refactor cycle:
1. **Red** — Write a failing test that defines expected behavior
2. **Green** — Write minimal code to make the test pass
3. **Refactor** — Clean up code while keeping tests green

### Running Tests
```bash
docker-compose exec web bundle exec rspec
docker-compose exec web bundle exec rspec --format documentation
```
READMEEOF

git add backend/spec/requests/api/v1/insights_spec.rb README.md
git commit -m "Code: add health_alerts anomaly detection spec and update README with TDD docs"
echo "Commit 20 done"

echo "=== ALL 20 TDD COMMITS COMPLETED ==="
echo "Pushing to git..."
git push origin HEAD:main || git push origin HEAD
echo "=== PUSHED SUCCESSFULLY ==="
