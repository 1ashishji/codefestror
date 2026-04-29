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
