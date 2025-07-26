require 'rails_helper'

RSpec.describe AcknowledgeDetailedProjectAssignment do
  let(:organization) { create(:organization) }
  let(:member) { create(:member, organization: organization) }
  let(:other_member) { create(:member, organization: organization) }
  let(:standard_project) { create(:standard_project, organization: organization) }
  let(:detailed_assignment) do
    create(:detailed_project_assignment,
           member: member,
           standard_project: standard_project,
           start_date: Date.current,
           end_date: Date.current + 1.week,
           allocation_percentage: 50.0)
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

      it 'fails when member and assignment belong to different organizations' do
        other_organization = create(:organization)
        other_member = create(:member, organization: other_organization)

        result = described_class.call(
          detailed_assignment: detailed_assignment,
          member: other_member
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Member must belong to same organization')
      end
    end
  end
end
