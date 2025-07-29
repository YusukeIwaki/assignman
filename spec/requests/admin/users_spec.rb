require 'rails_helper'
require 'csv'

RSpec.describe 'Admin::Users', type: :request do
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }

  around do |example|
    travel_to Time.zone.parse('2024-01-15 12:00:00') do
      example.run
    end
  end

  before do
    # Update user profiles and credentials
    user1.user_profile.update!(name: 'John Doe')
    user2.user_profile.update!(name: 'Jane Smith')
    user1.user_credential.update!(email: 'john@example.com')
    user2.user_credential.update!(email: 'jane@example.com')

    # Make user1 an admin
    create(:admin, user: user1)
  end

  describe 'GET /admin/users' do
    it 'returns users list' do
      get admin_users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('John Doe')
      expect(response.body).to include('Jane Smith')
    end
  end

  describe 'GET /admin/users/export' do
    it 'exports users as CSV with correct content type' do
      get export_admin_users_path
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('users_20240115.csv')
      
      # Parse the CSV content
      csv_data = CSV.parse(response.body, headers: true)
      
      expect(csv_data.length).to eq(2)
      expect(csv_data.headers).to eq(['ID', 'Name', 'Email', 'Admin', 'Created At'])
      
      # Check user data
      john_row = csv_data.find { |row| row['Name'] == 'John Doe' }
      expect(john_row['Email']).to eq('john@example.com')
      expect(john_row['Admin']).to eq('Yes')
      expect(john_row['Created At']).to eq('2024-01-15')
      
      jane_row = csv_data.find { |row| row['Name'] == 'Jane Smith' }
      expect(jane_row['Admin']).to eq('No')
    end
  end

  describe 'POST /admin/users/import' do
    it 'handles malformed CSV gracefully' do
      csv_file = Tempfile.new(['users', '.csv'])
      csv_file.write('invalid,"csv,content')
      csv_file.rewind

      post import_admin_users_path, params: {
        file: Rack::Test::UploadedFile.new(csv_file.path, 'text/csv')
      }

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include('Invalid CSV format')

      csv_file.close
      csv_file.unlink
    end

    it 'skips non-existent users in CSV' do
      invalid_csv = CSV.generate(headers: true) do |csv|
        csv << ['ID', 'Name', 'Email', 'Admin', 'Created At']
        csv << [user1.id, 'John Updated', 'john@example.com', 'No', '2024-01-15']
        csv << [99999, 'Non Existent', 'none@example.com', 'Yes', '2024-01-15']
      end

      csv_file = Tempfile.new(['users', '.csv'])
      csv_file.write(invalid_csv)
      csv_file.rewind

      post import_admin_users_path, params: {
        file: Rack::Test::UploadedFile.new(csv_file.path, 'text/csv')
      }

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:notice]).to eq('Successfully updated 1 users')

      # Verify only the valid user was updated
      user1.reload
      expect(user1.user_profile.name).to eq('John Updated')

      csv_file.close
      csv_file.unlink
    end
  end

  describe 'PUT /admin/users/:id' do
    it 'validates name presence' do
      put admin_user_path(user1), params: {
        user: { name: '', admin_status: 'yes' }
      }

      expect(response).to have_http_status(:ok) # Should render edit template, not redirect
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it 'validates name with whitespace only' do
      put admin_user_path(user1), params: {
        user: { name: '   ', admin_status: 'no' }
      }

      expect(response).to have_http_status(:ok) # Should render edit template, not redirect
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it 'updates user with valid name' do
      put admin_user_path(user1), params: {
        user: { name: 'Valid Name', admin_status: 'no' }
      }

      expect(response).to redirect_to(admin_users_path)
      follow_redirect!
      expect(response.body).to include('User updated successfully')
    end
  end
end