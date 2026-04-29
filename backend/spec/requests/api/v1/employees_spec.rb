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
