require 'rails_helper'
require 'csv'

RSpec.describe 'Admin Projects', type: :system do
  # rubocop:disable RSpec/LetSetup
  # These projects are displayed in the UI and used in assertions
  let!(:standard_project1) { create(:standard_project, name: 'Web Development', client_name: 'Client A', status: 'confirmed') }
  let!(:standard_project2) { create(:standard_project, name: 'Mobile App', client_name: 'Client B', status: 'tentative') }
  let!(:ongoing_project1) { create(:ongoing_project, name: 'Support Service', client_name: 'Client C', status: 'active') }
  let!(:ongoing_project2) { create(:ongoing_project, name: 'Maintenance', client_name: 'Client D', status: 'inactive') }
  # rubocop:enable RSpec/LetSetup

  around do |example|
    travel_to Time.zone.parse('2024-01-15 12:00:00') do
      example.run
    end
  end


  describe 'Projects index page' do
    before do
      visit admin_projects_path
    end

    it 'displays the admin layout with logo and navigation and projects list with correct information' do
      expect(page).to have_text('assignman')
      expect(page).to have_link('Users')
      expect(page).to have_link('Projects')
      expect(page).to have_text('Projects') # page title

      # Standard projects
      expect(page).to have_text('Web Development')
      expect(page).to have_text('Mobile App')

      # Ongoing projects
      expect(page).to have_text('Support Service')
      expect(page).to have_text('Maintenance')

      expect(page).to have_text('2024-01-15')

      expect(page).to have_link('Edit', href: edit_admin_project_path(standard_project1, type: 'standard'))
      expect(page).to have_link('Edit', href: edit_admin_project_path(ongoing_project1, type: 'ongoing'))
    end

    it 'shows project types correctly' do
      within('table tbody') do
        rows = page.all('tr')

        # Find standard project rows
        web_row = rows.find { |row| row.has_text?('Web Development') }
        expect(web_row).to have_text('Standard')
        expect(web_row).to have_text('SP')

        # Find ongoing project rows
        support_row = rows.find { |row| row.has_text?('Support Service') }
        expect(support_row).to have_text('Ongoing')
        expect(support_row).to have_text('OP')
      end
    end

    it 'has export and import buttons and can download CSV' do
      csv_content = nil
      page.driver.with_playwright_page do |playwright_page|
        download = playwright_page.expect_download do
          playwright_page.get_by_text('Export CSV').click
        end
        expect(download.suggested_filename).to eq('projects_20240115.csv')
        csv_content = File.read(download.path)
      end

      # Verify CSV content
      expect(csv_content).to be_present
      csv_data = CSV.parse(csv_content, headers: true)

      expect(csv_data.length).to eq(4) # 2 standard + 2 ongoing projects
      expect(csv_data.headers).to eq(['ID', 'Type', 'Name', 'Start Date', 'End Date', 'Budget Hours', 'Budget', 'Created At'])

      # Check standard project data
      web_row = csv_data.find { |row| row['Name'] == 'Web Development' }
      expect(web_row['Type']).to eq('Standard')
      expect(web_row['Created At']).to eq('2024-01-15')

      # Check ongoing project data
      support_row = csv_data.find { |row| row['Name'] == 'Support Service' }
      expect(support_row['Type']).to eq('Ongoing')

      expect(page).to have_button('Import CSV')
      expect(page).to have_field('file', type: 'file')
    end
  end

  describe 'CSV Import' do
    let!(:csv_content) do
      CSV.generate(headers: true) do |csv|
        csv << ['ID', 'Type', 'Name', 'Start Date', 'End Date', 'Budget Hours', 'Budget', 'Created At']
        csv << ["SP#{standard_project1.id}", 'Standard', 'Web Development Updated', '2024-01-01', '2024-06-30', '200', '', '2024-01-15']
        csv << ["OP#{ongoing_project1.id}", 'Ongoing', 'Support Service Updated', '', '', '', '600000', '2024-01-15']
      end
    end

    it 'imports CSV and updates project information' do
      visit admin_projects_path

      # Create a temporary CSV file
      csv_file = Tempfile.new(['projects', '.csv'])
      csv_file.write(csv_content)
      csv_file.rewind

      # Upload the CSV file
      attach_file('file', csv_file.path)
      click_button 'Import CSV'

      expect(page).to have_text('Successfully updated 2 projects')

      # Verify the updates in the UI
      expect(page).to have_text('Web Development Updated')
      expect(page).to have_text('Support Service Updated')

      # Verify the updates in the database
      standard_project1.reload
      ongoing_project1.reload

      expect(standard_project1.name).to eq('Web Development Updated')
      expect(standard_project1.budget_hours).to eq(200.0)

      expect(ongoing_project1.name).to eq('Support Service Updated')
      expect(ongoing_project1.budget).to eq(600000.0)

      csv_file.close
      csv_file.unlink
    end

    it 'shows error for invalid file type' do
      visit admin_projects_path

      # Create a temporary text file (not CSV)
      txt_file = Tempfile.new(['projects', '.txt'])
      txt_file.write('not a csv file')
      txt_file.rewind

      attach_file('file', txt_file.path)
      click_button 'Import CSV'

      expect(page).to have_text('Invalid file type')

      txt_file.close
      txt_file.unlink
    end

    it 'shows error when no file is selected' do
      visit admin_projects_path
      click_button 'Import CSV'

      expect(page).to have_text('Please select a CSV file')
    end
  end

  describe 'Navigation' do
    it 'highlights the active menu item' do
      visit admin_projects_path

      projects_link = find('a', text: 'Projects')
      expect(projects_link[:class]).to include('active')

      users_link = find('a', text: 'Users')
      expect(users_link[:class]).not_to include('active')
    end
  end

  describe 'Project editing' do
    it 'can edit a standard project from the index page' do
      visit admin_projects_path

      # Click edit link for standard project
      within('table tbody') do
        web_row = page.all('tr').find { |row| row.has_text?('Web Development') }
        web_row.click_link('Edit')
      end

      expect(page).to have_text('Edit Standard Project Information')
      expect(page).to have_field('project_name', with: 'Web Development')

      # Update the project
      fill_in 'project_name', with: 'Web Development Updated'
      click_button 'Update Project'

      expect(page).to have_text('Project updated successfully')
      expect(page).to have_text('Web Development Updated')

    end

    it 'can edit an ongoing project' do
      visit edit_admin_project_path(ongoing_project1, type: 'ongoing')

      expect(page).to have_text('Edit Ongoing Project Information')
      expect(page).to have_field('project_name', with: 'Support Service')

      # Update the project
      fill_in 'project_name', with: 'Premium Support'
      fill_in 'project_budget', with: '750000'
      click_button 'Update Project'

      expect(page).to have_text('Project updated successfully')
      expect(page).to have_text('Premium Support')

    end

    it 'can cancel editing and return to projects list' do
      visit edit_admin_project_path(standard_project1, type: 'standard')

      click_link 'Cancel'

      expect(page).to have_text('Projects')
      expect(page).to have_text('Web Development') # unchanged
    end

    it 'shows readonly fields for ID and Type' do
      visit edit_admin_project_path(standard_project1, type: 'standard')

      expect(page).to have_field(type: 'text', disabled: true, with: "SP#{standard_project1.id}")
      expect(page).to have_field(type: 'text', disabled: true, with: 'Standard')
    end

    it 'shows validation error when name is blank' do
      visit edit_admin_project_path(standard_project1, type: 'standard')

      # Clear the name field and submit
      fill_in 'project_name', with: ''
      click_button 'Update Project'

      # Should stay on edit page and show error
      expect(page).to have_text('Edit Standard Project Information')
      expect(page).to have_text("Name can't be blank")

      # Form should retain the status selection
    end

    it 'shows validation error for standard project when dates are invalid' do
      visit edit_admin_project_path(standard_project1, type: 'standard')

      # Set end date before start date
      fill_in 'project_start_date', with: '2024-06-01'
      fill_in 'project_end_date', with: '2024-01-01'
      click_button 'Update Project'

      # Should stay on edit page and show error
      expect(page).to have_text('Edit Standard Project Information')
      expect(page).to have_text('End date must be after start date')
    end
  end
end
