class ConfirmRoughProjectAssignment < BaseUseCase
  def call(rough_assignment:, administrator:)
    validate_inputs(rough_assignment, administrator)

    # Check if administrator has permission to confirm this assignment
    unless can_confirm_assignment?(administrator, rough_assignment)
      return failure(BaseUseCase::AuthorizationError.new('Administrator cannot confirm this assignment'))
    end

    # Ensure this is actually a rough assignment
    return failure(BaseUseCase::ValidationError.new('Assignment is not in rough status')) unless rough_assignment.rough?

    # Check capacity constraints before confirming
    if would_exceed_capacity?(rough_assignment)
      return failure(BaseUseCase::ValidationError.new('Confirming this assignment would exceed member capacity'))
    end

    # Change status from rough to confirmed
    rough_assignment.status = 'confirmed'
    rough_assignment.updated_at = Time.current

    if rough_assignment.save
      success(rough_assignment)
    else
      failure(BaseUseCase::ValidationError.new(rough_assignment.errors.full_messages.join(', ')))
    end
  rescue BaseUseCase::ValidationError => e
    failure(e)
  rescue StandardError => e
    failure(BaseUseCase::Error.new(e.message))
  end

  private

  def validate_inputs(rough_assignment, administrator)
    raise BaseUseCase::ValidationError, 'Rough assignment is required' unless rough_assignment
    raise BaseUseCase::ValidationError, 'Administrator is required' unless administrator

    return if administrator.organization_id == rough_assignment.project.organization_id

    raise BaseUseCase::ValidationError,
          'Administrator must belong to same organization'
  end

  def can_confirm_assignment?(administrator, assignment)
    # For now, simple check that administrator and assignment belong to same organization
    # In future, this could check for specific permissions
    administrator.organization_id == assignment.project.organization_id
  end

  def would_exceed_capacity?(assignment)
    member = assignment.member
    start_date = assignment.start_date
    end_date = assignment.end_date
    allocation_percentage = assignment.allocation_percentage

    # Get all confirmed assignments for this member (excluding the current one being confirmed)
    overlapping_assignments = member.assignments
                                    .where(status: %w[confirmed ongoing])
                                    .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                                    .where.not(id: assignment.id)

    # Check each date in the assignment period
    (start_date..end_date).each do |date|
      current_allocation = overlapping_assignments
                           .select { |a| date.between?(a.start_date, a.end_date) }
                           .sum(&:allocation_percentage)

      total_allocation = current_allocation + allocation_percentage

      return true if total_allocation > member.capacity
    end

    false
  end
end
