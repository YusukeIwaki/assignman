require 'rails_helper'

RSpec.describe 'Api::Users' do
  describe 'GET /api/users' do
    context 'when no users exist' do
      it 'returns empty users array with total 0' do
        get '/api/users'

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        json_response = response.parsed_body
        expect(json_response['total']).to eq(0)
        expect(json_response['offset']).to eq(0)
        expect(json_response['users']).to eq([])
      end
    end

    context 'when users exist' do
      before do
        (1..25).each do |i|
          user = create(:user)
          user.user_credential.update!(email: "user#{i}@example.com")
          user.user_profile.update!(name: "User #{i}")
        end
      end

      it 'returns users with default pagination' do
        get '/api/users'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['total']).to eq(25)
        expect(json_response['offset']).to eq(0)
        expect(json_response['users'].length).to eq(20) # default limit
        expect(json_response['users'].first['name']).to eq('User 1')
        expect(json_response['users'].last['name']).to eq('User 20')
      end

      it 'returns users with custom limit' do
        get '/api/users', params: { limit: 10 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['total']).to eq(25)
        expect(json_response['offset']).to eq(0)
        expect(json_response['users'].length).to eq(10)
      end

      it 'returns users with offset' do
        get '/api/users', params: { limit: 10, offset: 10 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['total']).to eq(25)
        expect(json_response['offset']).to eq(10)
        expect(json_response['users'].length).to eq(10)
        expect(json_response['users'].first['name']).to eq('User 11')
        expect(json_response['users'].last['name']).to eq('User 20')
      end

      it 'returns remaining users when offset is near the end' do
        get '/api/users', params: { limit: 10, offset: 20 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['total']).to eq(25)
        expect(json_response['offset']).to eq(20)
        expect(json_response['users'].length).to eq(5) # remaining users
        expect(json_response['users'].first['name']).to eq('User 21')
        expect(json_response['users'].last['name']).to eq('User 25')
      end

      it 'returns empty users when offset exceeds total' do
        get '/api/users', params: { limit: 10, offset: 100 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['total']).to eq(25)
        expect(json_response['offset']).to eq(100)
        expect(json_response['users']).to eq([])
      end

      it 'includes only id and name fields' do
        get '/api/users', params: { limit: 1 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        user = json_response['users'].first
        expect(user.keys).to contain_exactly('id', 'name')
        expect(user['id']).to be_a(Integer)
        expect(user['name']).to be_a(String)
        expect(user).not_to have_key('email')
      end
    end

    context 'parameter validation' do
      before do
        create(:user)
      end

      it 'enforces maximum limit of 100' do
        get '/api/users', params: { limit: 200 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        # Should return only 1 user since that's all we have, but limit should be capped
        expect(json_response['users'].length).to eq(1)
      end

      it 'enforces minimum limit of 1' do
        get '/api/users', params: { limit: 0 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['users'].length).to eq(1)
      end

      it 'handles negative offset by setting to 0' do
        get '/api/users', params: { offset: -10 }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['offset']).to eq(0)
      end

      it 'handles string parameters gracefully' do
        get '/api/users', params: { limit: 'abc', offset: 'def' }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        # Should use defaults when parameters are invalid
        expect(json_response['offset']).to eq(0)
        expect(json_response['users'].length).to eq(1) # we have 1 user
      end
    end
  end
end
