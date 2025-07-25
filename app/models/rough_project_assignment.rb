# == Schema Information
#
# Table name: rough_project_assignments
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
#  index_rough_project_assignments_on_member_id            (member_id)
#  index_rough_project_assignments_on_standard_project_id  (standard_project_id)
#
# Foreign Keys
#
#  member_id            (member_id => members.id)
#  standard_project_id  (standard_project_id => standard_projects.id)
#
class RoughProjectAssignment < ApplicationRecord
  belongs_to :standard_project
  belongs_to :member

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :allocation_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :end_date_after_start_date
  validate :no_overlapping_rough_assignments

  scope :for_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }
  scope :overlapping_with, lambda { |assignment|
    where.not(id: assignment.id).for_date_range(assignment.start_date, assignment.end_date)
  }

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def no_overlapping_rough_assignments
    return unless member && start_date && end_date

    overlapping = member.rough_project_assignments
                        .where.not(id: id)
                        .for_date_range(start_date, end_date)

    return unless overlapping.exists?

    errors.add(:base, 'Member already has overlapping rough assignment')
  end
end
