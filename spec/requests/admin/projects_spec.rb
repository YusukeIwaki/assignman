require 'rails_helper'
require 'csv'

RSpec.describe 'Admin::Projects', type: :request do
  let(:organization) { create(:organization, name: 'Test Organization') }
  let(:standard_project1) { create(:standard_project, organization: organization, name: 'Web Project', client_name: 'Client A') }
  let(:ongoing_project1) { create(:ongoing_project, organization: organization, name: 'Support Project', client_name: 'Client B') }

  around do |example|
    travel_to Time.zone.parse('2024-01-15 12:00:00') do
      example.run
    end
  end

  before do
    standard_project1
    ongoing_project1
  end

  describe 'GET /admin/projects' do
    it 'returns projects list' do
      get admin_projects_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Web Project')
      expect(response.body).to include('Support Project')
    end
  end

  describe 'GET /admin/projects/export' do
    it 'exports projects as CSV with correct content type' do
      get export_admin_projects_path

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('projects_20240115.csv')

      # Parse the CSV content
      csv_data = CSV.parse(response.body, headers: true)

      expect(csv_data.length).to eq(2)
      expect(csv_data.headers).to eq(['ID', 'Type', 'Organization', 'Name', 'Start Date', 'End Date', 'Budget Hours', 'Budget', 'Created At'])

      # Check standard project data
      standard_row = csv_data.find { |row| row['Name'] == 'Web Project' }
      expect(standard_row['Type']).to eq('Standard')
      expect(standard_row['Organization']).to eq('Test Organization')
      expect(standard_row['Created At']).to eq('2024-01-15')

      # Check ongoing project data
      ongoing_row = csv_data.find { |row| row['Name'] == 'Support Project' }
      expect(ongoing_row['Type']).to eq('Ongoing')
    end
  end

  describe 'POST /admin/projects/import' do
    it 'handles malformed CSV gracefully' do
      csv_file = Tempfile.new(['projects', '.csv'])
      csv_file.write('invalid,\"csv,content')
      csv_file.rewind

      post import_admin_projects_path, params: {
        file: Rack::Test::UploadedFile.new(csv_file.path, 'text/csv')
      }

      expect(response).to redirect_to(admin_projects_path)
      expect(flash[:alert]).to include('Invalid CSV format')

      csv_file.close
      csv_file.unlink
    end

    it 'skips non-existent projects in CSV' do
      valid_csv = CSV.generate(headers: true) do |csv|
        csv << ['ID', 'Type', 'Organization', 'Name', 'Start Date', 'End Date', 'Budget Hours', 'Budget', 'Created At']
        csv << ["SP#{standard_project1.id}", 'Standard', 'Test Organization', 'Updated Web Project', '2024-01-01', '2024-06-30', '200', '', '2024-01-15']
        csv << ['SP99999', 'Standard', 'Test Organization', 'Non Existent Project', '2024-01-01', '2024-06-30', '100', '', '2024-01-15']
      end

      csv_file = Tempfile.new(['projects', '.csv'])
      csv_file.write(valid_csv)
      csv_file.rewind

      post import_admin_projects_path, params: {
        file: Rack::Test::UploadedFile.new(csv_file.path, 'text/csv')
      }

      expect(response).to redirect_to(admin_projects_path)
      expect(flash[:notice]).to eq('Successfully updated 1 projects')

      # Verify only the valid project was updated
      standard_project1.reload
      expect(standard_project1.name).to eq('Updated Web Project')

      csv_file.close
      csv_file.unlink
    end

    it 'handles missing file parameter' do
      post import_admin_projects_path

      expect(response).to redirect_to(admin_projects_path)
      expect(flash[:alert]).to eq('Please select a CSV file')
    end

    it 'handles invalid file type' do
      txt_file = Tempfile.new(['projects', '.txt'])
      txt_file.write('not a csv file')
      txt_file.rewind

      post import_admin_projects_path, params: {
        file: Rack::Test::UploadedFile.new(txt_file.path, 'text/plain')
      }

      expect(response).to redirect_to(admin_projects_path)
      expect(flash[:alert]).to eq('Invalid file type')

      txt_file.close
      txt_file.unlink
    end
  end

  describe 'PUT /admin/projects/:id' do
    it 'validates name presence for standard project' do
      put admin_project_path(standard_project1), params: {
        type: 'standard',
        project: { name: '' }
      }

      expect(response).to have_http_status(:ok) # Should render edit template, not redirect
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it 'validates dates for standard project' do
      put admin_project_path(standard_project1), params: {
        type: 'standard',
        project: {
          name: 'Valid Name',
          start_date: '2024-06-01',
          end_date: '2024-01-01',
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('End date must be after start date')
    end

    it 'validates name presence for ongoing project' do
      put admin_project_path(ongoing_project1), params: {
        type: 'ongoing',
        project: { name: '' }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it 'updates standard project with valid data' do
      put admin_project_path(standard_project1), params: {
        type: 'standard',
        project: {
          name: 'Updated Name',
          status: 'confirmed',
          start_date: '2024-01-01',
          end_date: '2024-06-30'
        }
      }

      expect(response).to redirect_to(admin_projects_path)
      follow_redirect!
      expect(response.body).to include('Project updated successfully')

      standard_project1.reload
      expect(standard_project1.name).to eq('Updated Name')
    end

    it 'updates ongoing project with valid data' do
      put admin_project_path(ongoing_project1), params: {
        type: 'ongoing',
        project: {
          name: 'Updated Support',
          budget: '750000'
        }
      }

      expect(response).to redirect_to(admin_projects_path)
      follow_redirect!
      expect(response.body).to include('Project updated successfully')

      ongoing_project1.reload
      expect(ongoing_project1.name).to eq('Updated Support')
      expect(ongoing_project1.budget).to eq(750000.0)
    end
  end
end
