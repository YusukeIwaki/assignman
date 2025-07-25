class Skill < ApplicationRecord
  belongs_to :organization
  has_many :member_skills, dependent: :destroy
  has_many :members, through: :member_skills
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
end
