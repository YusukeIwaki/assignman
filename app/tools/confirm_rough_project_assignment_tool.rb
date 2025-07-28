# frozen_string_literal: true

# Tool for confirming rough project assignments via MCP
# This tool wraps the ConfirmRoughProjectAssignment use case
class ConfirmRoughProjectAssignmentTool < FastMcp::Tool
  description 'Confirm a rough assignment by converting it to a detailed assignment. ' \
              'This makes the assignment visible to members and enforces capacity constraints.'

  arguments do
    required(:rough_assignment_id).filled(:integer).description('The ID of the RoughProjectAssignment to confirm. Must be an existing rough assignment in the system.')
    required(:admin_id).filled(:integer).description('The ID of the User (administrator) confirming this assignment. Must have admin privileges in the same organization as the project.')
  end

  # Execute the use case with provided parameters
  def call(rough_assignment_id:, admin_id:)
    # Find the rough assignment and admin
    rough_assignment = RoughProjectAssignment.find(rough_assignment_id)
    admin = User.find(admin_id)

    # Execute the use case
    result = ConfirmRoughProjectAssignment.new.call(
      rough_assignment: rough_assignment,
      admin: admin
    )

    # Return the result in MCP format
    if result.success?
      {
        success: true,
        detailed_assignment: {
          id: result.data.id,
          project_id: result.data.standard_project_id,
          member_id: result.data.member_id,
          start_date: result.data.start_date.to_s,
          end_date: result.data.end_date.to_s,
          scheduled_hours: result.data.scheduled_hours,
          status: 'detailed',
          created_at: result.data.created_at.iso8601
        },
        message: 'Rough assignment successfully confirmed and converted to detailed assignment'
      }
    else
      {
        success: false,
        error: {
          type: result.error.class.name,
          message: result.error.message
        }
      }
    end
  rescue ActiveRecord::RecordNotFound => e
    {
      success: false,
      error: {
        type: 'RecordNotFound',
        message: e.message
      }
    }
  end
end