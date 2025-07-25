FactoryBot.define do
  factory :assignment do
    start_date { Date.current }
    end_date { Date.current + 1.month }
    allocation_percentage { 50.0 }
    project
    member
    
    after(:build) do |assignment|
      if assignment.member && assignment.project
        assignment.member.organization = assignment.project.organization
      end
    end
    
    trait :full_time do
      allocation_percentage { 100.0 }
    end
    
    trait :part_time do
      allocation_percentage { 25.0 }
    end
  end
end