# == Schema Information
#
# Table name: members
#
#  id              :integer          not null, primary key
#  capacity        :decimal(5, 1)
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_members_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
class Member < ApplicationRecord
  belongs_to :organization
  has_many :rough_project_assignments, dependent: :destroy
  has_many :detailed_project_assignments, dependent: :destroy
  has_many :ongoing_assignments, dependent: :destroy
  has_many :standard_projects, through: :detailed_project_assignments
  has_many :ongoing_projects, through: :ongoing_assignments
  has_many :member_skills, dependent: :destroy
  has_many :skills, through: :member_skills

  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 200 }

  def current_allocation(date = Date.current)
    detailed_allocation = detailed_project_assignments
                          .where('start_date <= ? AND end_date >= ?', date, date)
                          .sum(:allocation_percentage)

    ongoing_allocation = ongoing_assignments
                         .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
                         .sum(:allocation_percentage)

    detailed_allocation + ongoing_allocation
  end

  def available_capacity(date = Date.current)
    capacity - current_allocation(date)
  end
end
