require 'rails_helper'

RSpec.describe CreateDetailedProjectAssignmentFromRoughProjectAssignment do
  let(:organization) { create(:organization) }
  let(:admin) { create(:admin, organization: organization) }
  let(:member) { create(:member, organization: organization, capacity: 100.0) }
  let(:standard_project) { create(:standard_project, organization: organization) }
  let(:rough_assignment) do
    create(:rough_project_assignment,
           member: member,
           standard_project: standard_project,
           start_date: Date.current,
           end_date: Date.current + 1.week,
           allocation_percentage: 50.0)
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'creates detailed assignment from rough assignment' do
        result = described_class.call(
          rough_assignment: rough_assignment,
          admin: admin
        )

        expect(result.success?).to be true
        expect(result.data).to be_a(DetailedProjectAssignment)
        expect(result.data.member).to eq(member)
        expect(result.data.standard_project).to eq(standard_project)
        expect(result.data.start_date).to eq(rough_assignment.start_date)
        expect(result.data.end_date).to eq(rough_assignment.end_date)
        expect(result.data.allocation_percentage).to eq(rough_assignment.allocation_percentage)

        # Original rough assignment should be deleted
        expect { rough_assignment.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with capacity constraints' do
      let!(:existing_detailed_assignment) do
        create(:detailed_project_assignment,
               member: member,
               standard_project: standard_project,
               start_date: Date.current,
               end_date: Date.current + 1.week,
               allocation_percentage: 80.0)
      end

      it 'fails when creating would exceed member capacity' do
        result = described_class.call(
          rough_assignment: rough_assignment,
          admin: admin
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Creating this assignment would exceed member capacity')

        # Original rough assignment should still exist
        expect { rough_assignment.reload }.not_to raise_error
      end
    end

    context 'with invalid parameters' do
      it 'fails when rough assignment is missing' do
        result = described_class.call(
          rough_assignment: nil,
          admin: admin
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Rough assignment is required')
      end

      it 'fails when admin is missing' do
        result = described_class.call(
          rough_assignment: rough_assignment,
          admin: nil
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Admin is required')
      end
    end

    context 'with authorization' do
      it 'fails when admin belongs to different organization' do
        other_organization = create(:organization)
        other_admin = create(:admin, organization: other_organization)

        result = described_class.call(
          rough_assignment: rough_assignment,
          admin: other_admin
        )

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Admin must belong to same organization')
      end
    end
  end
end
