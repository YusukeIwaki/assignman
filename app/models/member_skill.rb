# == Schema Information
#
# Table name: member_skills
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  member_id  :integer          not null
#  skill_id   :integer          not null
#
# Indexes
#
#  index_member_skills_on_member_id               (member_id)
#  index_member_skills_on_member_id_and_skill_id  (member_id,skill_id) UNIQUE
#  index_member_skills_on_skill_id                (skill_id)
#
# Foreign Keys
#
#  member_id  (member_id => members.id)
#  skill_id   (skill_id => skills.id)
#
class MemberSkill < ApplicationRecord
  belongs_to :member
  belongs_to :skill

  validates :member_id, uniqueness: { scope: :skill_id }
  validate :member_and_skill_same_organization

  private

  def member_and_skill_same_organization
    return unless member && skill

    return unless member.organization_id != skill.organization_id

    errors.add(:skill,
               'must belong to the same organization as member')
  end
end
