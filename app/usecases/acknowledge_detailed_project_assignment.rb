class AcknowledgeDetailedProjectAssignment < BaseUseCase
  def call(detailed_assignment:, member:)
    validate_inputs(detailed_assignment, member)

    # Check if member has permission to acknowledge this assignment
    unless can_acknowledge_assignment?(member, detailed_assignment)
      return failure(BaseUseCase::AuthorizationError.new('Member cannot acknowledge this assignment'))
    end

    # For now, we just return success as acknowledgment
    # In the future, this could update an acknowledgment status on the assignment
    success(detailed_assignment)
  rescue BaseUseCase::ValidationError => e
    failure(e)
  rescue StandardError => e
    failure(BaseUseCase::Error.new(e.message))
  end

  private

  def validate_inputs(detailed_assignment, member)
    raise BaseUseCase::ValidationError, 'Detailed assignment is required' unless detailed_assignment
    raise BaseUseCase::ValidationError, 'Member is required' unless member

    return if member.organization_id == detailed_assignment.standard_project.organization_id

    raise BaseUseCase::ValidationError,
          'Member must belong to same organization'
  end

  def can_acknowledge_assignment?(member, assignment)
    # Member can only acknowledge their own assignments
    member.id == assignment.member_id
  end
end
