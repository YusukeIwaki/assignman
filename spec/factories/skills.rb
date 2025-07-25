FactoryBot.define do
  factory :skill do
    sequence(:name) { |n| "Skill #{n}" }
    organization
  end
end