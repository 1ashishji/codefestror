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
