FactoryBot.define do
  factory :ongoing_project do
    sequence(:name) { |n| "Ongoing Project #{n}" }
    status { 'active' }
    client_name { 'Example Client' }
    budget { 500_000 }
    notes { 'Ongoing project notes' }

    trait :inactive do
      status { 'inactive' }
    end
  end
end
