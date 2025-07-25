class CreateRoughProjectAssignment < BaseUseCase
  def call(standard_project:, member:, start_date:, end_date:, allocation_percentage:, administrator:)
    validate_inputs(standard_project, member, start_date, end_date, allocation_percentage, administrator)

    # Check if administrator has permission to manage this project
    unless can_manage_project?(administrator, standard_project)
      return failure(BaseUseCase::AuthorizationError.new('Administrator cannot manage this project'))
    end

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
      allocation_percentage: allocation_percentage
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

  def validate_inputs(standard_project, member, start_date, end_date, allocation_percentage, administrator)
    raise BaseUseCase::ValidationError, 'Project is required' unless standard_project
    raise BaseUseCase::ValidationError, 'Member is required' unless member
    raise BaseUseCase::ValidationError, 'Start date is required' unless start_date
    raise BaseUseCase::ValidationError, 'End date is required' unless end_date
    raise BaseUseCase::ValidationError, 'Allocation percentage is required' unless allocation_percentage
    raise BaseUseCase::ValidationError, 'Administrator is required' unless administrator

    unless standard_project.organization_id == member.organization_id
      raise BaseUseCase::ValidationError,
            'Project and member must belong to same organization'
    end
    return if administrator.organization_id == member.organization_id

    raise BaseUseCase::ValidationError,
          'Administrator must belong to same organization'
  end

  def can_manage_project?(administrator, standard_project)
    # For now, simple check that administrator and project belong to same organization
    # In future, this could check for specific permissions
    administrator.organization_id == standard_project.organization_id
  end

  def overlapping_rough_assignment_exists?(member, start_date, end_date, exclude_assignment_id)
    query = member.rough_project_assignments
                  .where('start_date <= ? AND end_date >= ?', end_date, start_date)

    query = query.where.not(id: exclude_assignment_id) if exclude_assignment_id

    query.exists?
  end
end
