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
