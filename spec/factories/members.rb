FactoryBot.define do
  factory :member do
    sequence(:name) { |n| "Member #{n}" }
    capacity { 100.0 }
    organization

    trait :with_skills do
      after(:create) do |member|
        create_list(:member_skill, 2, member: member)
      end
    end
  end
end
