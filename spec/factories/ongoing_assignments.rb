FactoryBot.define do
  factory :ongoing_assignment do
    ongoing_project
    member
    start_date { Date.current }
    end_date { nil } # indefinite by default
    allocation_percentage { 50.0 }

    trait :with_end_date do
      end_date { Date.current + 6.months }
    end
  end
end
