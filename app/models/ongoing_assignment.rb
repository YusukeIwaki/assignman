# == Schema Information
#
# Table name: ongoing_assignments
#
#  id                    :integer          not null, primary key
#  allocation_percentage :decimal(5, 1)    default(100.0), not null
#  end_date              :date
#  start_date            :date             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  member_id             :integer          not null
#  ongoing_project_id    :integer
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
  validates :allocation_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :end_date_after_start_date
  validate :member_capacity_not_exceeded

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

  def member_capacity_not_exceeded
    return unless member && start_date && allocation_percentage

    # For ongoing assignments without end_date, check a reasonable period
    check_end_date = end_date || (start_date + 1.year)

    # Sample weekly to avoid performance issues
    current_date = start_date
    while current_date <= check_end_date
      total_allocation = calculate_total_allocation_on_date(current_date)

      if total_allocation + allocation_percentage > member.capacity
        errors.add(:allocation_percentage, "would exceed member capacity on #{current_date}")
        break
      end

      current_date += 1.week
    end
  end

  def calculate_total_allocation_on_date(date)
    # Sum allocations from detailed assignments
    detailed_allocation = member.detailed_project_assignments
                                .where('start_date <= ? AND end_date >= ?', date, date)
                                .sum(:allocation_percentage)

    # Sum allocations from other ongoing assignments
    ongoing_allocation = member.ongoing_assignments
                               .where.not(id: id)
                               .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                               .sum(:allocation_percentage)

    detailed_allocation + ongoing_allocation
  end
end
