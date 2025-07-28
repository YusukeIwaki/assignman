require 'rails_helper'

RSpec.describe AcknowledgeDetailedProjectAssignment do
  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:standard_project) { create(:standard_project) }
  let(:detailed_assignment) do
    create(:detailed_project_assignment,
           member: member,
           standard_project: standard_project,
           start_date: standard_project.start_date,
           end_date: standard_project.start_date + 1.week,
           scheduled_hours: 8.0)
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'allows member to acknowledge their own assignment' do
        result = described_class.call(
          detailed_assignment: detailed_assignment,
          member: member
        )

        expect(result.success?).to be true
        expect(result.data).to eq(detailed_assignment)
      end
    end

    context 'with invalid parameters' do
      it 'fails when detailed assignment is missing' do
        result = described_class.call(
          detailed_assignment: nil,
          member: member
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Detailed assignment is required')
      end

      it 'fails when member is missing' do
        result = described_class.call(
          detailed_assignment: detailed_assignment,
          member: nil
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Member is required')
      end
    end

    context 'with authorization' do
      it 'denies access when member tries to acknowledge other member assignment' do
        result = described_class.call(
          detailed_assignment: detailed_assignment,
          member: other_member
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::AuthorizationError)
        expect(result.error.message).to eq('Member cannot acknowledge this assignment')
      end

    end
  end
end
