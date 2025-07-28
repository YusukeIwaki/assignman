# == Schema Information
#
# Table name: skills
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_skills_on_organization_id_and_name  (name) UNIQUE
#
class Skill < ApplicationRecord
  has_many :member_skills, dependent: :destroy
  has_many :members, through: :member_skills

  validates :name, presence: true, uniqueness: true
end
