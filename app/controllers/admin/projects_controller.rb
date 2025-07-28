require 'csv'

class Admin::ProjectsController < ApplicationController
  layout 'admin'

  def index
    @standard_projects = StandardProject.includes(:organization).order(:created_at)
    @ongoing_projects = OngoingProject.includes(:organization).order(:created_at)
  end

  def edit
    @project = find_project
    @project_type = params[:type]
  end

  def update
    @project = find_project
    @project_type = params[:type]

    project_params = params.require(:project).permit(:name, :notes, :start_date, :end_date, :budget_hours, :budget)

    # Validation
    @errors = []
    if project_params[:name].blank?
      @errors << "Name can't be blank"
    end

    if @project_type == 'standard'
      if project_params[:start_date].blank?
        @errors << "Start date can't be blank"
      end
      if project_params[:end_date].blank?
        @errors << "End date can't be blank"
      end
      if project_params[:start_date].present? && project_params[:end_date].present? &&
         Date.parse(project_params[:end_date]) < Date.parse(project_params[:start_date])
        @errors << "End date must be after start date"
      end
    end

    if @errors.any?
      flash.now[:alert] = @errors.join(', ')
      render :edit
      return
    end

    begin
      # Update based on project type
      if @project_type == 'standard'
        @project.update!(
          name: project_params[:name],
          notes: project_params[:notes],
          start_date: project_params[:start_date],
          end_date: project_params[:end_date],
          budget_hours: project_params[:budget_hours]
        )
      else # ongoing
        @project.update!(
          name: project_params[:name],
          notes: project_params[:notes],
          budget: project_params[:budget]
        )
      end

      redirect_to admin_projects_path, notice: 'Project updated successfully'
    rescue => e
      flash.now[:alert] = "Update failed: #{e.message}"
      render :edit
    end
  end

  def export
    @standard_projects = StandardProject.includes(:organization).order(:created_at)
    @ongoing_projects = OngoingProject.includes(:organization).order(:created_at)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Type', 'Organization', 'Name', 'Start Date', 'End Date', 'Budget Hours', 'Budget', 'Created At']

      @standard_projects.each do |project|
        csv << [
          "SP#{project.id}",
          'Standard',
          project.organization.name,
          project.name,
          project.start_date.strftime('%Y-%m-%d'),
          project.end_date.strftime('%Y-%m-%d'),
          project.budget_hours || '',
          '',
          project.created_at.strftime('%Y-%m-%d')
        ]
      end

      @ongoing_projects.each do |project|
        csv << [
          "OP#{project.id}",
          'Ongoing',
          project.organization.name,
          project.name,
          '',
          '',
          '',
          project.budget || '',
          project.created_at.strftime('%Y-%m-%d')
        ]
      end
    end

    send_data csv_data, filename: "projects_#{Date.current.strftime('%Y%m%d')}.csv", type: 'text/csv'
  end

  def import
    return redirect_to admin_projects_path, alert: 'Please select a CSV file' unless params[:file]

    file = params[:file]
    return redirect_to admin_projects_path, alert: 'Invalid file type' unless file.content_type == 'text/csv'

    begin
      csv_data = CSV.parse(file.read, headers: true)
      updated_count = 0
      errors = []

      csv_data.each_with_index do |row, index|
        line_number = index + 2 # +2 because index starts at 0 and we have a header row

        begin
          project_id = row['ID']&.strip
          next if project_id.blank?

          # Parse project type and ID
          if project_id.start_with?('SP')
            project = StandardProject.find_by(id: project_id[2..-1])
            project_type = 'standard'
          elsif project_id.start_with?('OP')
            project = OngoingProject.find_by(id: project_id[2..-1])
            project_type = 'ongoing'
          else
            next
          end

          next unless project

          # Update project fields
          name = row['Name']&.strip

          if name.present?
            project.name = name
          end

          # Update type-specific fields
          if project_type == 'standard'
            start_date = row['Start Date']&.strip
            end_date = row['End Date']&.strip
            budget_hours = row['Budget Hours']&.strip

            if start_date.present?
              project.start_date = Date.parse(start_date)
            end

            if end_date.present?
              project.end_date = Date.parse(end_date)
            end

            if budget_hours.present? && budget_hours.match?(/\A\d+(\.\d+)?\z/)
              project.budget_hours = budget_hours.to_f
            end
          else # ongoing
            budget = row['Budget']&.strip

            if budget.present? && budget.match?(/\A\d+(\.\d+)?\z/)
              project.budget = budget.to_f
            end
          end

          project.save!
          updated_count += 1
        rescue => e
          errors << "Line #{line_number}: #{e.message}"
        end
      end

      if errors.empty?
        redirect_to admin_projects_path, notice: "Successfully updated #{updated_count} projects"
      else
        redirect_to admin_projects_path, alert: "Import completed with errors: #{errors.join('; ')}"
      end
    rescue CSV::MalformedCSVError => e
      redirect_to admin_projects_path, alert: "Invalid CSV format: #{e.message}"
    rescue => e
      redirect_to admin_projects_path, alert: "Import failed: #{e.message}"
    end
  end

  private

  def find_project
    if params[:type] == 'standard'
      StandardProject.find(params[:id])
    else
      OngoingProject.find(params[:id])
    end
  end
end
