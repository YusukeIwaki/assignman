# == Schema Information
#
# Table name: ongoing_assignments
#
#  id                     :integer          not null, primary key
#  end_date               :date
#  start_date             :date             not null
#  weekly_scheduled_hours :decimal(5, 1)    not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  member_id              :integer          not null
#  ongoing_project_id     :integer
#
# Indexes
#
#  index_ongoing_assignments_on_member_id           (member_id)
#  index_ongoing_assignments_on_ongoing_project_id  (ongoing_project_id)
#
# Foreign Keys
#
#  member_id           (member_id => members.id)
#  ongoing_project_id  (ongoing_project_id => ongoing_projects.id)
#
class OngoingAssignment < ApplicationRecord
  belongs_to :ongoing_project
  belongs_to :member

  validates :start_date, presence: true
  validates :weekly_scheduled_hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 80 }
  validate :end_date_after_start_date
  validate :member_hours_not_exceeded

  scope :for_date_range, lambda { |start_date, end_date|
    where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', end_date, start_date)
  }
  scope :overlapping_with, lambda { |assignment|
    where.not(id: assignment.id).for_date_range(assignment.start_date, assignment.end_date || (Date.current + 1.year))
  }

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def member_hours_not_exceeded
    return unless member && start_date && weekly_scheduled_hours

    daily_capacity = member.standard_working_hours / 5.0
    daily_ongoing_hours = weekly_scheduled_hours / 5.0

    # Check the start date as representative
    return if start_date.saturday? || start_date.sunday?

    total_hours = calculate_total_hours_on_date(start_date)

    if total_hours + daily_ongoing_hours > daily_capacity
      errors.add(:weekly_scheduled_hours, "would exceed member capacity on #{start_date}")
    end
  end

  def calculate_total_hours_on_date(date)
    # Skip weekends
    return 0 if date.saturday? || date.sunday?

    # Sum hours from detailed assignments
    detailed_assignments = member.detailed_project_assignments
                                 .where('start_date <= ? AND end_date >= ?', date, date)

    detailed_hours = detailed_assignments.sum do |assignment|
      assignment.scheduled_hours / assignment.working_days_count
    end

    # Sum hours from other ongoing assignments (weekly hours / 5)
    ongoing_hours = member.ongoing_assignments
                          .where.not(id: id)
                          .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                          .sum('weekly_scheduled_hours / 5.0')

    detailed_hours + ongoing_hours
  end
end
