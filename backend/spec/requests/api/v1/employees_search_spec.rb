require 'rails_helper'

RSpec.describe 'Api::V1::Employees Search', type: :request do
  describe 'GET /api/v1/employees/search' do
    before(:each) do
      create(:employee, full_name: 'Alice Johnson')
      create(:employee, full_name: 'Bob Williams')
    end

    it 'returns matching employees for valid query' do
      get '/api/v1/employees/search', params: { q: 'Alice' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
    end

    it 'returns empty array for blank query' do
      get '/api/v1/employees/search', params: { q: '' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to eq([])
    end
  end
end

RSpec.describe 'Api::V1::Employees Error Handling', type: :request do
  describe 'error responses' do
    it 'returns bad request for missing required bulk_promote params' do
      post '/api/v1/employees/bulk_promote', params: {}
      expect(response).to have_http_status(:bad_request)
    end
  end
end
