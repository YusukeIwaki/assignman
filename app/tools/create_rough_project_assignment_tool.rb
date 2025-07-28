# frozen_string_literal: true

# Tool for creating rough project assignments via MCP
# This tool wraps the CreateRoughProjectAssignment use case
class CreateRoughProjectAssignmentTool < FastMcp::Tool
  description 'Create a rough (draft) assignment for project planning purposes. ' \
              'Rough assignments are not visible to members and allow flexible planning without capacity constraints.'

  arguments do
    required(:project_id).filled(:integer).description('The ID of the StandardProject to assign the member to. Must be an existing project in the system.')
    required(:member_id).filled(:integer).description('The ID of the Member to be assigned to the project. Must be an existing member in the same organization.')
    required(:start_date).filled(:string).description('The start date of the assignment in YYYY-MM-DD format. Can be outside project dates for planning flexibility.')
    required(:end_date).filled(:string).description('The end date of the assignment in YYYY-MM-DD format. Must be after start_date.')
    required(:allocation_percentage).filled(:integer).description('The percentage of the member\'s time allocated to this project (1-100). Multiple rough assignments can exceed 100% total for planning purposes.')
    required(:administrator_id).filled(:integer).description('The ID of the User (administrator) creating this assignment. Must have admin privileges in the organization.')
  end

  # Execute the use case with provided parameters
  def call(project_id:, member_id:, start_date:, end_date:, allocation_percentage:, administrator_id:)
    # Parse date strings to Date objects
    start_date_parsed = Date.parse(start_date)
    end_date_parsed = Date.parse(end_date)

    # Find the project and member
    project = StandardProject.find(project_id)
    member = Member.find(member_id)
    administrator = User.find(administrator_id)

    # Execute the use case
    result = CreateRoughProjectAssignment.new.call(
      project: project,
      member: member,
      start_date: start_date_parsed,
      end_date: end_date_parsed,
      allocation_percentage: allocation_percentage,
      administrator: administrator
    )

    # Return the result in MCP format
    if result.success?
      {
        success: true,
        assignment: {
          id: result.data.id,
          project_id: result.data.standard_project_id,
          member_id: result.data.member_id,
          start_date: result.data.start_date.to_s,
          end_date: result.data.end_date.to_s,
          allocation_percentage: result.data.scheduled_hours,
          status: 'rough',
          created_at: result.data.created_at.iso8601
        }
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
  rescue ArgumentError => e
    {
      success: false,
      error: {
        type: 'ArgumentError',
        message: "Invalid date format: #{e.message}"
      }
    }
  end
end