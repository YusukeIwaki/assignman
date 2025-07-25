FactoryBot.define do
  factory :user_credential do
    sequence(:email) { |n| "user#{n}@example.com" }
    password_digest { 'dummy_digest' }
    user
  end
end
