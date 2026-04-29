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
