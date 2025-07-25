FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    organization
  end
end