FactoryBot.define do
  factory :admin do
    organization
    user { association :user, organization: organization }
  end
end
