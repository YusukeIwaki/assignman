require 'csv'

class Admin::UsersController < ApplicationController
  layout 'admin'

  def index
    @users = User.includes(:user_profile, :admin).order(:created_at)
  end

  def edit
    @user = User.includes(:user_profile, :admin).find(params[:id])
  end

  def update
    @user = User.includes(:user_profile, :admin).find(params[:id])
    
    user_params = params.require(:user).permit(:name, :admin_status)
    
    # Validation
    @errors = []
    if user_params[:name].blank?
      @errors << "Name can't be blank"
    end
    
    if @errors.any?
      flash.now[:alert] = @errors.join(', ')
      render :edit
      return
    end
    
    begin
      # Update user profile name
      if @user.user_profile
        @user.user_profile.update!(name: user_params[:name])
      end
      
      # Update admin status
      admin_status = user_params[:admin_status]
      if admin_status == 'yes' && !@user.admin
        Admin.create!(user: @user)
      elsif admin_status == 'no' && @user.admin
        @user.admin.destroy!
      end
      
      redirect_to admin_users_path, notice: 'User updated successfully'
    rescue => e
      flash.now[:alert] = "Update failed: #{e.message}"
      render :edit
    end
  end

  def export
    @users = User.includes(:user_profile, :admin).order(:created_at)
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Email', 'Admin', 'Created At']
      
      @users.each do |user|
        csv << [
          user.id,
          user.name || '',
          user.email || '',
          user.admin.present? ? 'Yes' : 'No',
          user.created_at.strftime('%Y-%m-%d')
        ]
      end
    end

    send_data csv_data, filename: "users_#{Date.current.strftime('%Y%m%d')}.csv", type: 'text/csv'
  end

  def import
    return redirect_to admin_users_path, alert: 'Please select a CSV file' unless params[:file]

    file = params[:file]
    return redirect_to admin_users_path, alert: 'Invalid file type' unless file.content_type == 'text/csv'

    begin
      csv_data = CSV.parse(file.read, headers: true)
      updated_count = 0
      errors = []

      csv_data.each_with_index do |row, index|
        line_number = index + 2 # +2 because index starts at 0 and we have a header row
        
        begin
          user_id = row['ID']&.strip
          next if user_id.blank?
          
          user = User.find_by(id: user_id)
          next unless user
          
          # Update user profile name if provided
          name = row['Name']&.strip
          if name.present? && user.user_profile
            user.user_profile.update!(name: name)
          end
          
          # Update admin status
          admin_status = row['Admin']&.strip&.downcase
          if ['yes', 'no'].include?(admin_status)
            if admin_status == 'yes' && !user.admin
              Admin.create!(user: user)
            elsif admin_status == 'no' && user.admin
              user.admin.destroy!
            end
          end
          
          updated_count += 1
        rescue => e
          errors << "Line #{line_number}: #{e.message}"
        end
      end

      if errors.empty?
        redirect_to admin_users_path, notice: "Successfully updated #{updated_count} users"
      else
        redirect_to admin_users_path, alert: "Import completed with errors: #{errors.join('; ')}"
      end
    rescue CSV::MalformedCSVError => e
      redirect_to admin_users_path, alert: "Invalid CSV format: #{e.message}"
    rescue => e
      redirect_to admin_users_path, alert: "Import failed: #{e.message}"
    end
  end

  private

  def require_csv
    
  end
end