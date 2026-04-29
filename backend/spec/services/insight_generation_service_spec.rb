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
