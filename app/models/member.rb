class Member < ApplicationRecord
  belongs_to :organization
  belongs_to :role, optional: true
  has_many :assignments, dependent: :destroy
  has_many :projects, through: :assignments
  has_many :member_skills, dependent: :destroy
  has_many :skills, through: :member_skills

  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 200 }

  def current_allocation(date = Date.current)
    assignments.joins(:project)
               .where('assignments.start_date <= ? AND assignments.end_date >= ?', date, date)
               .sum(:allocation_percentage)
  end

  def available_capacity(date = Date.current)
    capacity - current_allocation(date)
  end
end
