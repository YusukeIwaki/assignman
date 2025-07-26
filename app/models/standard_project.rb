# == Schema Information
#
# Table name: standard_projects
#
#  id              :integer          not null, primary key
#  budget_hours    :decimal(10, 1)
#  client_name     :string
#  end_date        :date             not null
#  name            :string           not null
#  notes           :text
#  start_date      :date             not null
#  status          :string           default("tentative"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_standard_projects_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
class StandardProject < ApplicationRecord
  belongs_to :organization
  has_many :rough_project_assignments, dependent: :destroy
  has_many :detailed_project_assignments, dependent: :destroy
  has_one :project_plan, dependent: :destroy

  after_create :create_project_plan

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[tentative confirmed archived] }
  validate :end_date_after_start_date
  validate :budget_hours_is_positive

  scope :active, -> { where.not(status: 'archived') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :tentative, -> { where(status: 'tentative') }

  def total_scheduled_hours
    rough_hours = rough_project_assignments.sum(:scheduled_hours)
    detailed_hours = detailed_project_assignments.sum(:scheduled_hours)
    rough_hours + detailed_hours
  end

  def remaining_budget_hours
    return nil unless budget_hours

    budget_hours - total_scheduled_hours
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def budget_hours_is_positive
    return unless budget_hours

    errors.add(:budget_hours, 'must be positive') if budget_hours <= 0
  end

  def create_project_plan
    ProjectPlan.create!(standard_project: self)
  end
end
