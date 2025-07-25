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
