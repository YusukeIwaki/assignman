require 'rails_helper'

RSpec.describe GetMemberSchedule do
  let(:organization) { create(:organization) }
  let(:member) { create(:member, organization: organization, name: 'John Doe', standard_working_hours: 40.0) }
  let(:admin) { create(:admin, organization: organization) }
  let(:start_date) { Date.new(2024, 1, 8) } # Monday
  let(:end_date) { Date.new(2024, 1, 15) } # Next Monday

  describe '#call' do
    let(:valid_params) do
      {
        member: member,
        start_date: start_date,
        end_date: end_date,
        viewer: admin
      }
    end

    context 'with valid parameters' do
      it 'returns member schedule successfully' do
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data).to be_a(Hash)
        expect(result.data[:member_name]).to eq('John Doe')
        expect(result.data[:start_date]).to eq(start_date)
        expect(result.data[:end_date]).to eq(end_date)
        expect(result.data[:daily_schedule]).to be_an(Array)
        expect(result.data[:summary]).to be_a(Hash)
      end

      it 'returns empty schedule when no assignments exist' do
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data[:daily_schedule].length).to eq(8) # 1 week + 1 day
        expect(result.data[:summary][:total_assignments]).to eq(0)
        expect(result.data[:summary][:average_hours]).to eq(0.0)
        expect(result.data[:summary][:max_hours]).to eq(0.0)
      end
    end

    context 'with assignments' do
      around do |example|
        travel_to Date.new(2024, 1, 1) do
          example.run
        end
      end
      let!(:standard_project) do
        create(:standard_project, organization: organization, name: 'Project Alpha',
                                  start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 1, 31))
      end
      let!(:ongoing_project) do
        create(:ongoing_project, organization: organization, name: 'Project Beta')
      end

      let!(:detailed_assignment) do
        create(:detailed_project_assignment,
               member: member,
               standard_project: standard_project,
               start_date: Date.new(2024, 1, 8),    # Monday
               end_date: Date.new(2024, 1, 10),     # Wednesday
               scheduled_hours: 6.0)  # 2 hours per day * 3 days
      end

      let!(:ongoing_assignment) do
        create(:ongoing_assignment,
               member: member,
               ongoing_project: ongoing_project,
               start_date: Date.new(2024, 1, 10),   # Wednesday
               end_date: nil,
               weekly_scheduled_hours: 10.0)  # 2 hours per day
      end

      let!(:rough_assignment) do
        create(:rough_project_assignment,
               member: member,
               standard_project: standard_project,
               start_date: Date.new(2024, 1, 13),   # Saturday
               end_date: Date.new(2024, 1, 14),     # Sunday
               scheduled_hours: 10.0)
      end

      it 'includes confirmed and ongoing assignments but excludes rough assignments' do
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data[:summary][:total_assignments]).to eq(2) # confirmed + ongoing, not rough

        # Check specific days
        monday = result.data[:daily_schedule].find { |d| d[:date] == Date.new(2024, 1, 8) }
        expect(monday[:assignments].length).to eq(1)
        expect(monday[:assignments].first[:project_name]).to eq('Project Alpha')
        expect(monday[:total_hours]).to eq(2.0) # 6 hours / 3 days

        wednesday = result.data[:daily_schedule].find { |d| d[:date] == Date.new(2024, 1, 10) }
        expect(wednesday[:assignments].length).to eq(2) # Both assignments overlap
        expect(wednesday[:total_hours]).to eq(4.0) # 2.0 from detailed + 2.0 from ongoing

        saturday = result.data[:daily_schedule].find { |d| d[:date] == Date.new(2024, 1, 13) }
        expect(saturday[:assignments].length).to eq(1) # Only ongoing (weekends still show ongoing)
        expect(saturday[:assignments].first[:project_name]).to eq('Project Beta')
        expect(saturday[:total_hours]).to eq(0.0) # No hours on weekends
      end

      it 'calculates summary statistics correctly' do
        result = described_class.call(**valid_params)

        expect(result.data[:summary][:max_hours]).to be > 0
        expect(result.data[:summary][:average_hours]).to be > 0
      end

      it 'includes assignment details' do
        result = described_class.call(**valid_params)

        monday_schedule = result.data[:daily_schedule]
                                .find { |d| d[:date] == Date.new(2024, 1, 8) }
        assignment_info = monday_schedule[:assignments].first

        expect(assignment_info[:id]).to eq(detailed_assignment.id)
        expect(assignment_info[:project_name]).to eq('Project Alpha')
        expect(assignment_info[:project_id]).to eq(standard_project.id)
        expect(assignment_info[:daily_hours]).to eq(2.0)
        expect(assignment_info[:start_date]).to eq(Date.new(2024, 1, 8))
        expect(assignment_info[:end_date]).to eq(Date.new(2024, 1, 10))
      end
    end

    context 'with invalid parameters' do
      it 'fails when member is missing' do
        result = described_class.call(**valid_params, member: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Member is required')
      end

      it 'fails when start_date is missing' do
        result = described_class.call(**valid_params, start_date: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Start date is required')
      end

      it 'fails when end_date is missing' do
        result = described_class.call(**valid_params, end_date: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('End date is required')
      end

      it 'fails when viewer is missing' do
        result = described_class.call(**valid_params, viewer: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Viewer is required')
      end

      it 'fails when end_date is before start_date' do
        result = described_class.call(**valid_params, start_date: Date.new(2024, 1, 15),
                                                      end_date: Date.new(2024, 1, 8))

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('End date must be after start date')
      end
    end

    context 'with authorization' do
      it 'allows member to view their own schedule' do
        result = described_class.call(**valid_params, viewer: member)

        expect(result.success?).to be true
      end

      it 'allows admin from same organization to view member schedule' do
        result = described_class.call(**valid_params, viewer: admin)

        expect(result.success?).to be true
      end

      it 'denies access to admin from different organization' do
        other_organization = create(:organization)
        other_admin = create(:admin, organization: other_organization)

        result = described_class.call(**valid_params, viewer: other_admin)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::AuthorizationError)
        expect(result.error.message).to eq('Viewer cannot access this member schedule')
      end

      it 'denies access to member from different organization' do
        other_organization = create(:organization)
        other_member = create(:member, organization: other_organization)

        result = described_class.call(**valid_params, viewer: other_member)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::AuthorizationError)
        expect(result.error.message).to eq('Viewer cannot access this member schedule')
      end
    end
  end
end
