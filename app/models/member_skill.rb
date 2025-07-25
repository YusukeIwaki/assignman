class MemberSkill < ApplicationRecord
  belongs_to :member
  belongs_to :skill
  
  validates :member_id, uniqueness: { scope: :skill_id }
  validate :member_and_skill_same_organization
  
  private
  
  def member_and_skill_same_organization
    return unless member && skill
    
    errors.add(:skill, 'must belong to the same organization as member') if member.organization_id != skill.organization_id
  end
end
