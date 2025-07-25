class Role < ApplicationRecord
  belongs_to :organization
  has_many :members, dependent: :nullify
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
end
