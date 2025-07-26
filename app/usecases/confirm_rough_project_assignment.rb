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
      allocation_percentage: rough_assignment.allocation_percentage
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
    # For now, simple check that admin and assignment belong to same organization
    # In future, this could check for specific permissions
    admin.organization_id == assignment.standard_project.organization_id
  end

  def would_exceed_capacity?(assignment)
    member = assignment.member
    start_date = assignment.start_date
    end_date = assignment.end_date
    allocation_percentage = assignment.allocation_percentage

    # Check each date in the assignment period
    (start_date..end_date).each do |date|
      # Get allocations from detailed assignments
      detailed_allocation = member.detailed_project_assignments
                                  .where('start_date <= ? AND end_date >= ?', date, date)
                                  .sum(:allocation_percentage)

      # Get allocations from ongoing assignments
      ongoing_allocation = member.ongoing_assignments
                                 .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                                 .sum(:allocation_percentage)

      total_allocation = detailed_allocation + ongoing_allocation + allocation_percentage

      return true if total_allocation > member.capacity
    end

    false
  end
end
