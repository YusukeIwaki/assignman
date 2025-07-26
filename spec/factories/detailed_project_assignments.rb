FactoryBot.define do
  factory :detailed_project_assignment do
    standard_project
    member
    start_date { Date.current }
    end_date { Date.current + 1.month }
    scheduled_hours { 80.0 }
  end
end
