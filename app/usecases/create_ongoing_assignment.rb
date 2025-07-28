class CreateOngoingAssignment < BaseUseCase
  def call(ongoing_project:, member:, start_date:, end_date:, weekly_scheduled_hours:, admin:)
    validate_inputs(ongoing_project, member, start_date, end_date, weekly_scheduled_hours, admin)

    # For ongoing assignments, we need to check capacity constraints immediately
    if would_exceed_capacity?(member, start_date, end_date, weekly_scheduled_hours, nil)
      return failure(BaseUseCase::ValidationError.new('Assignment would exceed member capacity'))
    end

    # Create ongoing assignment
    assignment = OngoingAssignment.new(
      ongoing_project: ongoing_project,
      member: member,
      start_date: start_date,
      end_date: end_date,
      weekly_scheduled_hours: weekly_scheduled_hours
    )

    if assignment.save
      success(assignment)
    else
      failure(BaseUseCase::ValidationError.new(assignment.errors.full_messages.join(', ')))
    end
  rescue BaseUseCase::ValidationError => e
    failure(e)
  rescue StandardError => e
    failure(BaseUseCase::Error.new(e.message))
  end

  private

  def validate_inputs(ongoing_project, member, start_date, _end_date, weekly_scheduled_hours, admin)
    raise BaseUseCase::ValidationError, 'Project is required' unless ongoing_project
    raise BaseUseCase::ValidationError, 'Member is required' unless member
    raise BaseUseCase::ValidationError, 'Start date is required' unless start_date
    raise BaseUseCase::ValidationError, 'Weekly scheduled hours is required' unless weekly_scheduled_hours
    raise BaseUseCase::ValidationError, 'Admin is required' unless admin

    # NOTE: end_date is optional for ongoing assignments (can be nil for indefinite assignments)
  end

  def would_exceed_capacity?(member, start_date, end_date, weekly_scheduled_hours, exclude_assignment_id)
    # Determine the actual end date for checking - if nil, check for a reasonable period (e.g., 1 year)
    check_end_date = end_date || (start_date + 1.year)
    daily_capacity = member.standard_working_hours / 5.0
    daily_hours = weekly_scheduled_hours / 5.0

    # Sample weekly to avoid performance issues for long periods
    current_date = start_date
    while current_date <= check_end_date
      # Skip weekends
      if !current_date.saturday? && !current_date.sunday?
        # Get hours from detailed assignments
        detailed_hours = member.detailed_project_assignments
                               .where('start_date <= ? AND end_date >= ?', current_date, current_date)
                               .sum do |da|
          da.scheduled_hours / da.working_days_count
        end

        # Get hours from other ongoing assignments
        ongoing_hours = member.ongoing_assignments
                              .where.not(id: exclude_assignment_id)
                              .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)',
                                     current_date, current_date)
                              .sum('weekly_scheduled_hours / 5.0')

        total_hours = detailed_hours + ongoing_hours + daily_hours

        return true if total_hours > daily_capacity
      end

      current_date += 1.week # Check weekly instead of daily for performance
    end

    false
  end
end
