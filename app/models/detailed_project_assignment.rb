# == Schema Information
#
# Table name: detailed_project_assignments
#
#  id                    :integer          not null, primary key
#  allocation_percentage :decimal(5, 1)    default(100.0), not null
#  end_date              :date             not null
#  start_date            :date             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  member_id             :integer          not null
#  standard_project_id   :integer
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
  validates :allocation_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :end_date_after_start_date
  validate :dates_within_project_period
  validate :member_capacity_not_exceeded

  scope :for_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }
  scope :overlapping_with, lambda { |assignment|
    where.not(id: assignment.id).for_date_range(assignment.start_date, assignment.end_date)
  }

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

  def member_capacity_not_exceeded
    return unless member && start_date && end_date && allocation_percentage

    # Check against other detailed assignments and ongoing assignments
    (start_date..end_date).each do |date|
      total_allocation = calculate_total_allocation_on_date(date)

      if total_allocation + allocation_percentage > member.capacity
        errors.add(:allocation_percentage, "would exceed member capacity on #{date}")
        break
      end
    end
  end

  def calculate_total_allocation_on_date(date)
    # Sum allocations from other detailed assignments
    detailed_allocation = member.detailed_project_assignments
                                .where.not(id: id)
                                .where('start_date <= ? AND end_date >= ?', date, date)
                                .sum(:allocation_percentage)

    # Sum allocations from ongoing assignments
    ongoing_allocation = member.ongoing_assignments
                               .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                               .sum(:allocation_percentage)

    detailed_allocation + ongoing_allocation
  end
end
