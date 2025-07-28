# == Schema Information
#
# Table name: ongoing_projects
#
#  id          :integer          not null, primary key
#  budget      :decimal(15, 2)
#  client_name :string
#  name        :string           not null
#  notes       :text
#  status      :string           default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class OngoingProject < ApplicationRecord
  has_many :ongoing_assignments, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  validate :budget_is_positive

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  private

  def budget_is_positive
    return unless budget

    errors.add(:budget, 'must be positive') if budget <= 0
  end
end
