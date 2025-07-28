# == Schema Information
#
# Table name: project_plans
#
#  id                  :integer          not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  standard_project_id :integer          not null
#
# Indexes
#
#  index_project_plans_on_standard_project_id  (standard_project_id) UNIQUE
#
# Foreign Keys
#
#  standard_project_id  (standard_project_id => standard_projects.id)
#
class ProjectPlan < ApplicationRecord
  belongs_to :standard_project
  has_many :rough_project_assignments, through: :standard_project
  has_many :detailed_project_assignments, through: :standard_project

  validates :standard_project_id, uniqueness: true

  def total_rough_hours
    rough_project_assignments.sum(:scheduled_hours)
  end

  def total_detailed_hours
    detailed_project_assignments.sum(:scheduled_hours)
  end

  def total_scheduled_hours
    total_rough_hours + total_detailed_hours
  end

  def budget_remaining
    return nil unless standard_project.budget_hours

    standard_project.budget_hours - total_scheduled_hours
  end

  def convert_rough_to_detailed(rough_assignment)
    return nil unless rough_assignment.standard_project_id == standard_project_id

    ActiveRecord::Base.transaction do
      detailed = DetailedProjectAssignment.create!(
        standard_project: standard_project,
        member: rough_assignment.member,
        start_date: rough_assignment.start_date,
        end_date: rough_assignment.end_date,
        scheduled_hours: rough_assignment.scheduled_hours
      )

      rough_assignment.destroy!

      detailed
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to convert rough to detailed: #{e.message}"
    nil
  end

  def members_with_assignments
    member_ids = (rough_project_assignments.pluck(:member_id) +
                  detailed_project_assignments.pluck(:member_id)).uniq

    Member.where(id: member_ids)
  end

  def assignments_for_member(member)
    {
      rough: rough_project_assignments.where(member: member),
      detailed: detailed_project_assignments.where(member: member)
    }
  end
end
