FactoryBot.define do
  factory :assignment do
    start_date { Date.current }
    end_date { Date.current + 1.month }
    allocation_percentage { 50.0 }
    status { 'confirmed' }
    project
    member

    after(:build) do |assignment|
      assignment.member.organization = assignment.project.organization if assignment.member && assignment.project
    end

    trait :rough do
      status { 'rough' }
    end

    trait :confirmed do
      status { 'confirmed' }
    end

    trait :ongoing do
      status { 'ongoing' }
    end

    trait :full_time do
      allocation_percentage { 100.0 }
    end

    trait :part_time do
      allocation_percentage { 25.0 }
    end
  end
end
