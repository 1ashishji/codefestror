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
