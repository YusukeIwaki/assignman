FactoryBot.define do
  factory :rough_project_assignment do
    standard_project
    member
    start_date { Date.current }
    end_date { Date.current + 1.month }
    allocation_percentage { 100.0 }
  end
end
