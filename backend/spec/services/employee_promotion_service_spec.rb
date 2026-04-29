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
