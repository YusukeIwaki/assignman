FactoryBot.define do
  factory :user_profile do
    name { "Test User" }
    bio { "This is a test user profile" }
    avatar_url { nil }
    user
  end
end