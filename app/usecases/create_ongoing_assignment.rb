class CreateOngoingAssignment < BaseUseCase
  def call(project:, member:, start_date:, end_date:, allocation_percentage:, administrator:)
    validate_inputs(project, member, start_date, end_date, allocation_percentage, administrator)

    # Check if administrator has permission to manage this project
    unless can_manage_project?(administrator, project)
      return failure(BaseUseCase::AuthorizationError.new('Administrator cannot manage this project'))
    end

    # For ongoing assignments, we need to check capacity constraints immediately
    if would_exceed_capacity?(member, start_date, end_date, allocation_percentage, nil)
      return failure(BaseUseCase::ValidationError.new('Assignment would exceed member capacity'))
    end

    # Create ongoing assignment (using assignment model with ongoing status)
    assignment = Assignment.new(
      project: project,
      member: member,
      start_date: start_date,
      end_date: end_date,
      allocation_percentage: allocation_percentage,
      status: 'ongoing' # This indicates it's an ongoing assignment
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

  def validate_inputs(project, member, start_date, _end_date, allocation_percentage, administrator)
    raise BaseUseCase::ValidationError, 'Project is required' unless project
    raise BaseUseCase::ValidationError, 'Member is required' unless member
    raise BaseUseCase::ValidationError, 'Start date is required' unless start_date
    raise BaseUseCase::ValidationError, 'Allocation percentage is required' unless allocation_percentage
    raise BaseUseCase::ValidationError, 'Administrator is required' unless administrator

    unless project.organization_id == member.organization_id
      raise BaseUseCase::ValidationError,
            'Project and member must belong to same organization'
    end
    return if administrator.organization_id == member.organization_id

    raise BaseUseCase::ValidationError,
          'Administrator must belong to same organization'

    # NOTE: end_date is optional for ongoing assignments (can be nil for indefinite assignments)
  end

  def can_manage_project?(administrator, project)
    # For now, simple check that administrator and project belong to same organization
    # In future, this could check for specific permissions
    administrator.organization_id == project.organization_id
  end

  def would_exceed_capacity?(member, start_date, end_date, allocation_percentage, exclude_assignment_id)
    # Determine the actual end date for checking - if nil, check for a reasonable period (e.g., 1 year)
    check_end_date = end_date || (start_date + 1.year)

    # Get all confirmed and ongoing assignments for this member (excluding the current one if updating)
    overlapping_assignments = member.assignments
                                    .where(status: %w[confirmed ongoing])
                                    .where('start_date <= ? AND (end_date >= ? OR end_date IS NULL)',
                                           check_end_date, start_date)

    overlapping_assignments = overlapping_assignments.where.not(id: exclude_assignment_id) if exclude_assignment_id

    # Check each date in the assignment period (sample every week to avoid performance issues for long periods)
    current_date = start_date
    while current_date <= check_end_date
      current_allocation = overlapping_assignments
                           .select { |a| date_in_assignment_range?(current_date, a.start_date, a.end_date) }
                           .sum(&:allocation_percentage)

      total_allocation = current_allocation + allocation_percentage

      return true if total_allocation > member.capacity

      current_date += 1.week # Check weekly instead of daily for performance
    end

    false
  end

  def date_in_assignment_range?(date, start_date, end_date)
    return false if date < start_date
    return true if end_date.nil? # Ongoing assignment with no end date

    date <= end_date
  end
end
