FactoryBot.define do
  factory :member_skill do
    member
    skill

    # Ensure member and skill belong to the same organization
    before(:create) do |member_skill|
      member_skill.skill.organization = member_skill.member.organization if member_skill.member && member_skill.skill
    end
  end
end
