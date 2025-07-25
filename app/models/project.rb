# == Schema Information
#
# Table name: projects
#
#  id              :integer          not null, primary key
#  budget          :decimal(15, 2)
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
#  index_projects_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
class Project < ApplicationRecord
  belongs_to :organization
  has_many :assignments, dependent: :destroy
  has_many :members, through: :assignments

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[tentative confirmed archived] }
  validate :end_date_after_start_date

  enum :status, { tentative: 'tentative', confirmed: 'confirmed', archived: 'archived' }

  scope :active, -> { where.not(status: 'archived') }
  scope :for_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
end
