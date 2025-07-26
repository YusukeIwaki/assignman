# == Schema Information
#
# Table name: detailed_project_assignments
#
#  id                  :integer          not null, primary key
#  end_date            :date             not null
#  scheduled_hours     :decimal(5, 1)    not null
#  start_date          :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  member_id           :integer          not null
#  standard_project_id :integer
#
# Indexes
#
#  index_detailed_project_assignments_on_member_id            (member_id)
#  index_detailed_project_assignments_on_standard_project_id  (standard_project_id)
#
# Foreign Keys
#
#  member_id            (member_id => members.id)
#  standard_project_id  (standard_project_id => standard_projects.id)
#
class DetailedProjectAssignment < ApplicationRecord
  belongs_to :standard_project
  belongs_to :member

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :scheduled_hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999 }
  validate :end_date_after_start_date
  validate :dates_within_project_period
  validate :member_hours_not_exceeded

  scope :for_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }
  scope :overlapping_with, lambda { |assignment|
    where.not(id: assignment.id).for_date_range(assignment.start_date, assignment.end_date)
  }

  def working_days_count
    return 0 unless start_date && end_date

    (start_date..end_date).count { |date| !date.saturday? && !date.sunday? }
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def dates_within_project_period
    return unless standard_project && start_date && end_date

    errors.add(:start_date, 'must be within project period') if start_date < standard_project.start_date
    errors.add(:end_date, 'must be within project period') if end_date > standard_project.end_date
  end

  def member_hours_not_exceeded
    return unless member && start_date && end_date && scheduled_hours

    # Check daily capacity constraints
    (start_date..end_date).each do |date|
      next if date.saturday? || date.sunday?

      daily_scheduled = calculate_total_hours_on_date(date)
      daily_capacity = member.standard_working_hours / 5.0

      if daily_scheduled + (scheduled_hours / working_days_count) > daily_capacity
        errors.add(:scheduled_hours, "would exceed member capacity on #{date}")
        break
      end
    end
  end

  def calculate_total_hours_on_date(date)
    # Sum hours from other detailed assignments
    other_assignments = member.detailed_project_assignments
                              .where.not(id: id)
                              .where('start_date <= ? AND end_date >= ?', date, date)

    other_hours = other_assignments.sum do |assignment|
      assignment.scheduled_hours / assignment.working_days_count
    end

    # Sum hours from ongoing assignments (weekly hours / 5)
    ongoing_hours = member.ongoing_assignments
                          .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                          .sum('weekly_scheduled_hours / 5.0')

    other_hours + ongoing_hours
  end
end
