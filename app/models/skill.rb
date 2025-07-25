# == Schema Information
#
# Table name: skills
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_skills_on_organization_id           (organization_id)
#  index_skills_on_organization_id_and_name  (organization_id,name) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
class Skill < ApplicationRecord
  belongs_to :organization
  has_many :member_skills, dependent: :destroy
  has_many :members, through: :member_skills

  validates :name, presence: true, uniqueness: { scope: :organization_id }
end
