# frozen_string_literal: true

# Tool for retrieving member schedules via MCP
# This tool wraps the GetMemberSchedule use case
class GetMemberScheduleTool < FastMcp::Tool
  description 'Retrieve the confirmed schedule for a member within a specified date range. ' \
              'Shows detailed and ongoing assignments with daily breakdown and capacity utilization.'

  arguments do
    required(:member_id).filled(:integer).description('The ID of the Member whose schedule to retrieve. Must be an existing member in the system.')
    required(:start_date).filled(:string).description('The start date for the schedule period in YYYY-MM-DD format. Must be a valid date.')
    required(:end_date).filled(:string).description('The end date for the schedule period in YYYY-MM-DD format. Must be after start_date.')
    required(:viewer_id).filled(:integer).description('The ID of the User or Member requesting to view the schedule. Members can view their own schedule, administrators can view any member in their organization.')
    required(:viewer_type).filled(:string).description('The type of viewer: "User" for administrators, "Member" for team members viewing their own schedule.')
  end

  # Execute the use case with provided parameters
  def call(member_id:, start_date:, end_date:, viewer_id:, viewer_type:)
    # Parse date strings to Date objects
    start_date_parsed = Date.parse(start_date)
    end_date_parsed = Date.parse(end_date)

    # Find the member and viewer
    member = Member.find(member_id)
    
    # Find viewer based on type
    viewer = case viewer_type
             when 'User'
               User.find(viewer_id)
             when 'Member'
               Member.find(viewer_id)
             else
               raise ArgumentError, "Invalid viewer_type: #{viewer_type}"
             end

    # Execute the use case
    result = GetMemberSchedule.new.call(
      member: member,
      start_date: start_date_parsed,
      end_date: end_date_parsed,
      viewer: viewer
    )

    # Return the result in MCP format
    if result.success?
      schedule_data = result.data
      {
        success: true,
        schedule: {
          member_id: schedule_data[:member_id],
          member_name: schedule_data[:member_name],
          standard_working_hours: schedule_data[:standard_working_hours],
          period: {
            start_date: schedule_data[:start_date].to_s,
            end_date: schedule_data[:end_date].to_s
          },
          daily_schedule: schedule_data[:daily_schedule].map do |day|
            {
              date: day[:date].to_s,
              is_weekend: day[:is_weekend],
              total_hours: day[:total_hours],
              assignments: day[:assignments].map do |assignment|
                {
                  id: assignment[:id],
                  project_name: assignment[:project_name],
                  project_id: assignment[:project_id],
                  project_type: assignment[:project_type],
                  daily_hours: assignment[:daily_hours],
                  start_date: assignment[:start_date].to_s,
                  end_date: assignment[:end_date]&.to_s
                }
              end
            }
          end,
          summary: {
            total_assignments: schedule_data[:summary][:total_assignments],
            average_daily_hours: schedule_data[:summary][:average_hours],
            max_daily_hours: schedule_data[:summary][:max_hours],
            total_scheduled_hours: schedule_data[:summary][:total_scheduled_hours]
          }
        },
        message: 'Member schedule retrieved successfully'
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
        message: e.message
      }
    }
  end
end