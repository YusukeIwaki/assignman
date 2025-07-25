FactoryBot.define do
  factory :user do
    organization
    
    after(:create) do |user|
      create(:user_credential, user: user)
      create(:user_profile, user: user)
    end
  end
end
