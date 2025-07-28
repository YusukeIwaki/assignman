FactoryBot.define do
  factory :user do
    after(:create) do |user|
      create(:user_credential, user: user)
      create(:user_profile, user: user)
    end
  end
end
