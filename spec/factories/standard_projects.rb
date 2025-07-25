FactoryBot.define do
  factory :standard_project do
    organization
    sequence(:name) { |n| "Standard Project #{n}" }
    start_date { Date.current }
    end_date { Date.current + 3.months }
    status { 'tentative' }
    client_name { 'Example Client' }
    budget { 1_000_000 }
    notes { 'Project notes' }

    trait :confirmed do
      status { 'confirmed' }
    end

    trait :archived do
      status { 'archived' }
    end
  end
end
