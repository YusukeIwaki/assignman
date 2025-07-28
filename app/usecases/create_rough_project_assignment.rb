class CreateRoughProjectAssignment < BaseUseCase
  def call(standard_project:, member:, start_date:, end_date:, scheduled_hours:, admin:)
    validate_inputs(standard_project, member, start_date, end_date, scheduled_hours, admin)

    # Check for overlapping rough assignments
    if overlapping_rough_assignment_exists?(member, start_date, end_date, nil)
      return failure(BaseUseCase::ValidationError.new('Member already has overlapping rough assignment'))
    end

    # Create rough assignment
    assignment = RoughProjectAssignment.new(
      standard_project: standard_project,
      member: member,
      start_date: start_date,
      end_date: end_date,
      scheduled_hours: scheduled_hours
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

  def validate_inputs(standard_project, member, start_date, end_date, scheduled_hours, admin)
    raise BaseUseCase::ValidationError, 'Project is required' unless standard_project
    raise BaseUseCase::ValidationError, 'Member is required' unless member
    raise BaseUseCase::ValidationError, 'Start date is required' unless start_date
    raise BaseUseCase::ValidationError, 'End date is required' unless end_date
    raise BaseUseCase::ValidationError, 'Scheduled hours is required' unless scheduled_hours
    raise BaseUseCase::ValidationError, 'Admin is required' unless admin
  end

  def overlapping_rough_assignment_exists?(member, start_date, end_date, exclude_assignment_id)
    query = member.rough_project_assignments
                  .where('start_date <= ? AND end_date >= ?', end_date, start_date)

    query = query.where.not(id: exclude_assignment_id) if exclude_assignment_id

    query.exists?
  end
end
