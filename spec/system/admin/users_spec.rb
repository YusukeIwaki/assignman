require 'rails_helper'
require 'csv'

RSpec.describe 'Admin Users', type: :system do
  let(:organization) { create(:organization, name: 'Test Organization') }
  let(:user1) { create(:user, organization: organization) }
  let(:user2) { create(:user, organization: organization) }

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
    create(:admin, user: user1, organization: organization)
  end

  describe 'Users index page' do
    before do
      visit admin_users_path
    end

    it 'displays the admin layout with logo and navigation and users list with correct information' do
      expect(page).to have_text('assignman')
      expect(page).to have_link('Users')
      expect(page).to have_link('Projects')
      expect(page).to have_text('Users') # page title

      expect(page).to have_text('John Doe')
      expect(page).to have_text('Jane Smith')
      expect(page).to have_text('john@example.com')
      expect(page).to have_text('jane@example.com')
      expect(page).to have_text('Test Organization')
      expect(page).to have_text('2024-01-15')

      expect(page).to have_link('Edit', href: edit_admin_user_path(user1))
      expect(page).to have_link('Edit', href: edit_admin_user_path(user2))
    end

    it 'shows admin status correctly' do
      within('table tbody') do
        rows = page.all('tr')

        # Find John's row (should be admin)
        john_row = rows.find { |row| row.has_text?('John Doe') }
        expect(john_row).to have_text('Yes')

        # Find Jane's row (should not be admin)
        jane_row = rows.find { |row| row.has_text?('Jane Smith') }
        expect(jane_row).to have_text('No')
      end
    end

    it 'has export and import buttons and can download CSV' do
      csv_content = nil
      page.driver.with_playwright_page do |playwright_page|
        download = playwright_page.expect_download do
          playwright_page.get_by_text('Export CSV').click
        end
        expect(download.suggested_filename).to eq('users_20240115.csv')
        csv_content = File.read(download.path)
      end

      # Verify CSV content
      expect(csv_content).to be_present
      csv_data = CSV.parse(csv_content, headers: true)

      expect(csv_data.length).to eq(2)
      expect(csv_data.headers).to eq(['ID', 'Organization', 'Name', 'Email', 'Admin', 'Created At'])

      # Check user data
      john_row = csv_data.find { |row| row['Name'] == 'John Doe' }
      expect(john_row['Organization']).to eq('Test Organization')
      expect(john_row['Email']).to eq('john@example.com')
      expect(john_row['Admin']).to eq('Yes')
      expect(john_row['Created At']).to eq('2024-01-15')

      jane_row = csv_data.find { |row| row['Name'] == 'Jane Smith' }
      expect(jane_row['Admin']).to eq('No')

      expect(page).to have_button('Import CSV')
      expect(page).to have_field('file', type: 'file')
    end
  end

  describe 'CSV Import' do
    let(:csv_content) do
      CSV.generate(headers: true) do |csv|
        csv << ['ID', 'Organization', 'Name', 'Email', 'Admin', 'Created At']
        csv << [user1.id, 'Test Organization', 'John Updated', 'john@example.com', 'No', '2024-01-15']
        csv << [user2.id, 'Test Organization', 'Jane Updated', 'jane@example.com', 'Yes', '2024-01-15']
      end
    end

    it 'imports CSV and updates user information' do
      visit admin_users_path

      # Create a temporary CSV file
      csv_file = Tempfile.new(['users', '.csv'])
      csv_file.write(csv_content)
      csv_file.rewind

      # Upload the CSV file
      attach_file('file', csv_file.path)
      click_button 'Import CSV'

      expect(page).to have_text('Successfully updated 2 users')

      # Verify the updates in the UI
      expect(page).to have_text('John Updated')
      expect(page).to have_text('Jane Updated')

      # Verify the updates in the database
      user1.reload
      user2.reload

      expect(user1.user_profile.name).to eq('John Updated')
      expect(user1.admin).to be_nil # Admin status removed

      expect(user2.user_profile.name).to eq('Jane Updated')
      expect(user2.admin).to be_present # Admin status added

      csv_file.close
      csv_file.unlink
    end

    it 'shows error for invalid file type' do
      visit admin_users_path

      # Create a temporary text file (not CSV)
      txt_file = Tempfile.new(['users', '.txt'])
      txt_file.write('not a csv file')
      txt_file.rewind

      attach_file('file', txt_file.path)
      click_button 'Import CSV'

      expect(page).to have_text('Invalid file type')

      txt_file.close
      txt_file.unlink
    end

    it 'shows error when no file is selected' do
      visit admin_users_path
      click_button 'Import CSV'

      expect(page).to have_text('Please select a CSV file')
    end
  end

  describe 'Navigation' do
    it 'highlights the active menu item' do
      visit admin_users_path

      users_link = find('a', text: 'Users')
      expect(users_link[:class]).to include('active')

      projects_link = find('a', text: 'Projects')
      expect(projects_link[:class]).not_to include('active')
    end
  end

  describe 'User editing' do
    it 'can edit a user from the index page' do
      visit admin_users_path
      
      # Click edit link for John Doe
      within('table tbody') do
        john_row = page.all('tr').find { |row| row.has_text?('John Doe') }
        john_row.click_link('Edit')
      end

      expect(page).to have_text('Edit User')
      expect(page).to have_field('user_name', with: 'John Doe')
      expect(page).to have_select('user_admin_status', selected: 'Yes')

      # Update the user
      fill_in 'user_name', with: 'John Updated'
      select 'No', from: 'user_admin_status'
      click_button 'Update User'

      expect(page).to have_text('User updated successfully')
      expect(page).to have_text('John Updated')

      # Verify the admin status was updated
      within('table tbody') do
        john_row = page.all('tr').find { |row| row.has_text?('John Updated') }
        expect(john_row).to have_text('No')
      end
    end

    it 'can edit user and change admin status from No to Yes' do
      visit edit_admin_user_path(user2)

      expect(page).to have_text('Edit User')
      expect(page).to have_field('user_name', with: 'Jane Smith')
      expect(page).to have_select('user_admin_status', selected: 'No')

      # Update the user
      fill_in 'user_name', with: 'Jane Admin'
      select 'Yes', from: 'user_admin_status'
      click_button 'Update User'

      expect(page).to have_text('User updated successfully')
      expect(page).to have_text('Jane Admin')

      # Verify the admin status was updated
      within('table tbody') do
        jane_row = page.all('tr').find { |row| row.has_text?('Jane Admin') }
        expect(jane_row).to have_text('Yes')
      end
    end

    it 'can cancel editing and return to users list' do
      visit edit_admin_user_path(user1)

      click_link 'Cancel'

      expect(page).to have_text('Users')
      expect(page).to have_text('John Doe') # unchanged
    end

    it 'shows readonly fields for ID, Organization, and Email' do
      visit edit_admin_user_path(user1)

      expect(page).to have_field(type: 'text', disabled: true, with: user1.id.to_s)
      expect(page).to have_field(type: 'text', disabled: true, with: 'Test Organization')
      expect(page).to have_field(type: 'text', disabled: true, with: 'john@example.com')
    end

    it 'shows validation error when name is blank' do
      visit edit_admin_user_path(user1)
      
      # Clear the name field and submit
      fill_in 'user_name', with: ''
      click_button 'Update User'
      
      # Should stay on edit page and show error
      expect(page).to have_text('Edit User')
      expect(page).to have_text("Name can't be blank")
      
      # Form should retain the admin status selection
      expect(page).to have_select('user_admin_status', selected: 'Yes')
    end

    it 'shows validation error when name is only whitespace' do
      visit edit_admin_user_path(user2)
      
      # Fill with only spaces and submit
      fill_in 'user_name', with: '   '
      click_button 'Update User'
      
      # Should stay on edit page and show error
      expect(page).to have_text('Edit User')
      expect(page).to have_text("Name can't be blank")
      
      # Form should retain the admin status selection
      expect(page).to have_select('user_admin_status', selected: 'No')
    end
  end
end
