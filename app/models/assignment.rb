# == Schema Information
#
# Table name: assignments
#
#  id                    :integer          not null, primary key
#  allocation_percentage :decimal(5, 1)
#  end_date              :date
#  start_date            :date             not null
#  status                :string           default("confirmed"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  member_id             :integer          not null
#  project_id            :integer          not null
#
# Indexes
#
#  index_assignments_on_member_id   (member_id)
#  index_assignments_on_project_id  (project_id)
#  index_assignments_on_status      (status)
#
# Foreign Keys
#
#  member_id   (member_id => members.id)
#  project_id  (project_id => projects.id)
#
class Assignment < ApplicationRecord
  belongs_to :project
  belongs_to :member

  validates :start_date, presence: true
  validates :end_date, presence: true, unless: :ongoing?
  validates :allocation_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :status, presence: true, inclusion: { in: %w[rough confirmed ongoing] }
  validate :end_date_after_start_date
  validate :dates_within_project_period
  validate :member_capacity_not_exceeded

  attribute :status, :string, default: 'confirmed'
  enum :status, { rough: 'rough', confirmed: 'confirmed', ongoing: 'ongoing' }

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
    return unless project && start_date
    return if rough? # Skip project period validation for rough assignments
    return if ongoing? # Skip project period validation for ongoing assignments

    errors.add(:start_date, 'must be within project period') if start_date < project.start_date
    errors.add(:end_date, 'must be within project period') if end_date && end_date > project.end_date
  end

  def member_capacity_not_exceeded
    return unless member && start_date && allocation_percentage
    return if rough? # Skip capacity validation for rough assignments

    # For ongoing assignments without end_date, check a reasonable period (e.g., 3 months)
    check_end_date = end_date || (start_date + 3.months)

    overlapping_assignments = member.assignments.where.not(status: 'rough').overlapping_with(self)

    (start_date..check_end_date).each do |date|
      current_allocation = overlapping_assignments
                           .select { |a| date_in_assignment_range?(date, a.start_date, a.end_date) }
                           .sum(&:allocation_percentage)

      total_allocation = current_allocation + allocation_percentage

      if total_allocation > member.capacity
        errors.add(:allocation_percentage, "would exceed member capacity on #{date}")
        break
      end
    end
  end

  def date_in_assignment_range?(date, start_date, end_date)
    return false if date < start_date
    return true if end_date.nil? # Ongoing assignment with no end date

    date <= end_date
  end
end
