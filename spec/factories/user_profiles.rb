FactoryBot.define do
  factory :user_profile do
    sequence(:name) { |n| "Test User #{n}" }
    bio { "This is a test user profile" }
    avatar_url { nil }
    user
  end
end