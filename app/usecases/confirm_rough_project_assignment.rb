class ConfirmRoughProjectAssignment < BaseUseCase
  def call(rough_assignment:, admin:)
    validate_inputs(rough_assignment, admin)

    # Check if admin has permission to confirm this assignment
    unless can_confirm_assignment?(admin, rough_assignment)
      return failure(BaseUseCase::AuthorizationError.new('Admin cannot confirm this assignment'))
    end

    # Check capacity constraints before confirming
    if would_exceed_capacity?(rough_assignment)
      return failure(BaseUseCase::ValidationError.new('Confirming this assignment would exceed member capacity'))
    end

    # Create a new detailed assignment based on the rough assignment
    detailed_assignment = DetailedProjectAssignment.new(
      standard_project: rough_assignment.standard_project,
      member: rough_assignment.member,
      start_date: rough_assignment.start_date,
      end_date: rough_assignment.end_date,
      scheduled_hours: rough_assignment.scheduled_hours
    )

    if detailed_assignment.save
      # Delete the rough assignment after creating the detailed one
      rough_assignment.destroy
      success(detailed_assignment)
    else
      failure(BaseUseCase::ValidationError.new(detailed_assignment.errors.full_messages.join(', ')))
    end
  rescue BaseUseCase::ValidationError => e
    failure(e)
  rescue StandardError => e
    failure(BaseUseCase::Error.new(e.message))
  end

  private

  def validate_inputs(rough_assignment, admin)
    raise BaseUseCase::ValidationError, 'Rough assignment is required' unless rough_assignment
    raise BaseUseCase::ValidationError, 'Admin is required' unless admin

    return if admin.organization_id == rough_assignment.standard_project.organization_id

    raise BaseUseCase::ValidationError,
          'Admin must belong to same organization'
  end

  def can_confirm_assignment?(admin, assignment)
    # Admin can confirm assignments for projects in their organization
    admin.organization_id == assignment.standard_project.organization_id
  end

  def would_exceed_capacity?(assignment)
    member = assignment.member
    start_date = assignment.start_date
    end_date = assignment.end_date
    scheduled_hours = assignment.scheduled_hours

    # Calculate working days in the assignment period
    working_days = (start_date..end_date).count { |date| !date.saturday? && !date.sunday? }
    daily_hours = scheduled_hours / working_days.to_f
    daily_capacity = member.standard_working_hours / 5.0

    # Check each working day in the assignment period
    (start_date..end_date).each do |date|
      next if date.saturday? || date.sunday?

      # Get hours from detailed assignments
      detailed_hours = member.detailed_project_assignments
                             .where('start_date <= ? AND end_date >= ?', date, date)
                             .sum do |da|
        da.scheduled_hours / da.working_days_count
      end

      # Get hours from ongoing assignments (weekly hours / 5)
      ongoing_hours = member.ongoing_assignments
                            .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                            .sum('weekly_scheduled_hours / 5.0')

      total_hours = detailed_hours + ongoing_hours + daily_hours

      return true if total_hours > daily_capacity
    end

    false
  end
end
