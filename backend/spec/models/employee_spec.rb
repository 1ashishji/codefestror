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
