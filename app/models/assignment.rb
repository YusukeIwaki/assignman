class Assignment < ApplicationRecord
  belongs_to :project
  belongs_to :member
  
  validates :start_date, :end_date, presence: true
  validates :allocation_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :end_date_after_start_date
  validate :dates_within_project_period
  validate :member_capacity_not_exceeded
  
  scope :for_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }
  scope :overlapping_with, ->(assignment) { where.not(id: assignment.id).for_date_range(assignment.start_date, assignment.end_date) }
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
  
  def dates_within_project_period
    return unless project && start_date && end_date
    
    errors.add(:start_date, 'must be within project period') if start_date < project.start_date
    errors.add(:end_date, 'must be within project period') if end_date > project.end_date
  end
  
  def member_capacity_not_exceeded
    return unless member && start_date && end_date && allocation_percentage
    
    overlapping_assignments = member.assignments.overlapping_with(self)
    
    (start_date..end_date).each do |date|
      current_allocation = overlapping_assignments
                          .select { |a| date.between?(a.start_date, a.end_date) }
                          .sum(&:allocation_percentage)
      
      total_allocation = current_allocation + allocation_percentage
      
      if total_allocation > member.capacity
        errors.add(:allocation_percentage, "would exceed member capacity on #{date}")
        break
      end
    end
  end
end
