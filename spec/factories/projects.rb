FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    client_name { "Test Client" }
    start_date { Date.current }
    end_date { Date.current + 3.months }
    status { 'tentative' }
    budget { 1000000.0 }
    notes { "Test project notes" }
    organization

    trait :confirmed do
      status { 'confirmed' }
    end
    
    trait :archived do
      status { 'archived' }
    end
    
    trait :with_assignments do
      after(:create) do |project|
        create_list(:assignment, 2, project: project)
      end
    end
  end
end