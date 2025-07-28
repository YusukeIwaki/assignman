# frozen_string_literal: true

# Tool for creating ongoing assignments via MCP
# This tool wraps the CreateOngoingAssignment use case
class CreateOngoingAssignmentTool < FastMcp::Tool
  description 'Create an ongoing assignment for continuous work. ' \
              'Unlike rough assignments, ongoing assignments are immediately confirmed and visible to members.'

  arguments do
    required(:ongoing_project_id).filled(:integer).description('The ID of the OngoingProject to assign the member to. Must be an existing ongoing project in the system.')
    required(:member_id).filled(:integer).description('The ID of the Member to be assigned to the ongoing project. Must be an existing member in the same organization.')
    required(:start_date).filled(:string).description('The start date of the ongoing assignment in YYYY-MM-DD format. Must be a valid date.')
    optional(:end_date).maybe(:string).description('The end date of the assignment in YYYY-MM-DD format. Can be null for indefinite ongoing work. If provided, must be after start_date.')
    required(:weekly_scheduled_hours).filled(:integer).description('The number of hours per week allocated to this ongoing project (1-40). Used to calculate daily capacity constraints.')
    required(:admin_id).filled(:integer).description('The ID of the User (administrator) creating this assignment. Must have admin privileges in the organization.')
  end

  # Execute the use case with provided parameters
  def call(ongoing_project_id:, member_id:, start_date:, weekly_scheduled_hours:, admin_id:, end_date: nil)
    # Parse date strings to Date objects
    start_date_parsed = Date.parse(start_date)
    end_date_parsed = end_date ? Date.parse(end_date) : nil

    # Find the ongoing project, member, and admin
    ongoing_project = OngoingProject.find(ongoing_project_id)
    member = Member.find(member_id)
    admin = User.find(admin_id)

    # Execute the use case
    result = CreateOngoingAssignment.new.call(
      ongoing_project: ongoing_project,
      member: member,
      start_date: start_date_parsed,
      end_date: end_date_parsed,
      weekly_scheduled_hours: weekly_scheduled_hours,
      admin: admin
    )

    # Return the result in MCP format
    if result.success?
      {
        success: true,
        assignment: {
          id: result.data.id,
          ongoing_project_id: result.data.ongoing_project_id,
          member_id: result.data.member_id,
          start_date: result.data.start_date.to_s,
          end_date: result.data.end_date&.to_s,
          weekly_scheduled_hours: result.data.weekly_scheduled_hours,
          status: 'ongoing',
          created_at: result.data.created_at.iso8601
        },
        message: 'Ongoing assignment created successfully'
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