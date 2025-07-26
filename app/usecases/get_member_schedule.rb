class GetMemberSchedule < BaseUseCase
  def call(member:, start_date:, end_date:, viewer:)
    validate_inputs(member, start_date, end_date, viewer)

    # Check if viewer has permission to view this member's schedule
    unless can_view_schedule?(viewer, member)
      return failure(BaseUseCase::AuthorizationError.new('Viewer cannot access this member schedule'))
    end

    # Get detailed assignments
    detailed_assignments = member.detailed_project_assignments
                                 .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                                 .includes(:standard_project)
                                 .order(:start_date)

    # Get ongoing assignments
    ongoing_assignments = member.ongoing_assignments
                                .where('start_date <= ? AND (end_date >= ? OR end_date IS NULL)', end_date, start_date)
                                .includes(:ongoing_project)
                                .order(:start_date)

    # Combine all assignments
    assignments = detailed_assignments + ongoing_assignments

    # Group assignments by date for calendar view
    schedule_data = build_schedule_data(member, assignments, start_date, end_date)

    success(schedule_data)
  rescue BaseUseCase::ValidationError => e
    failure(e)
  rescue StandardError => e
    failure(BaseUseCase::Error.new(e.message))
  end

  private

  def validate_inputs(member, start_date, end_date, viewer)
    raise BaseUseCase::ValidationError, 'Member is required' unless member
    raise BaseUseCase::ValidationError, 'Start date is required' unless start_date
    raise BaseUseCase::ValidationError, 'End date is required' unless end_date
    raise BaseUseCase::ValidationError, 'Viewer is required' unless viewer
    raise BaseUseCase::ValidationError, 'End date must be after start date' unless end_date >= start_date
  end

  def can_view_schedule?(viewer, member)
    # Member can view their own schedule
    return true if viewer == member

    # Admins can view schedules of members in their organization
    return viewer.organization_id == member.organization_id if viewer.is_a?(Admin) && member.is_a?(Member)

    # Legacy Users (administrators) can view schedules of members in their organization
    return viewer.organization_id == member.organization_id if viewer.is_a?(User) && member.is_a?(Member)

    false
  end

  def build_schedule_data(member, assignments, start_date, end_date)
    # Create a hash with date as key and assignment info as value
    daily_schedule = {}

    # Initialize all dates with empty arrays
    (start_date..end_date).each do |date|
      daily_schedule[date] = {
        date: date,
        assignments: [],
        total_allocation: 0.0
      }
    end

    # Populate with assignment data
    assignments.each do |assignment|
      assignment_start = [assignment.start_date, start_date].max
      assignment_end = assignment.end_date ? [assignment.end_date, end_date].min : end_date

      (assignment_start..assignment_end).each do |date|
        next unless daily_schedule[date]

        project = assignment.respond_to?(:standard_project) ? assignment.standard_project : assignment.ongoing_project

        assignment_info = {
          id: assignment.id,
          project_name: project.name,
          project_id: project.id,
          project_type: assignment.class.name.underscore,
          allocation_percentage: assignment.allocation_percentage,
          start_date: assignment.start_date,
          end_date: assignment.end_date
        }

        daily_schedule[date][:assignments] << assignment_info
        daily_schedule[date][:total_allocation] += assignment.allocation_percentage
      end
    end

    # Convert to array format for easier consumption
    {
      member_id: member.id,
      member_name: member.name,
      start_date: start_date,
      end_date: end_date,
      daily_schedule: daily_schedule.values,
      summary: {
        total_assignments: assignments.count,
        average_allocation: calculate_average_allocation(daily_schedule),
        max_allocation: calculate_max_allocation(daily_schedule)
      }
    }
  end

  def calculate_average_allocation(daily_schedule)
    return 0.0 if daily_schedule.empty?

    total = daily_schedule.values.sum { |day| day[:total_allocation] }
    (total / daily_schedule.size).round(1)
  end

  def calculate_max_allocation(daily_schedule)
    return 0.0 if daily_schedule.empty?

    daily_schedule.values.pluck(:total_allocation).max
  end
end
