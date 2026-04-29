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
