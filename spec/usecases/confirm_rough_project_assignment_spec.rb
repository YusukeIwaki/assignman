require 'rails_helper'

RSpec.describe ConfirmRoughProjectAssignment do
  let(:organization) { create(:organization) }
  let(:administrator) { create(:user, organization: organization) }
  let(:project) { create(:project, organization: organization) }
  let(:member) { create(:member, organization: organization, capacity: 100.0) }
  let(:rough_assignment) { create(:assignment, :rough, project: project, member: member, allocation_percentage: 50.0) }

  describe '#call' do
    let(:valid_params) do
      {
        rough_assignment: rough_assignment,
        administrator: administrator
      }
    end

    context 'with valid parameters' do
      it 'confirms rough assignment successfully' do
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data).to be_a(Assignment)
        expect(result.data.status).to eq('confirmed')
        expect(result.data.id).to eq(rough_assignment.id)
      end

      it 'updates the assignment status in database' do
        expect { described_class.call(**valid_params) }.to change {
          rough_assignment.reload.status
        }.from('rough').to('confirmed')
      end

      it 'updates the updated_at timestamp' do
        original_time = rough_assignment.updated_at
        sleep(0.01) # Ensure time difference

        described_class.call(**valid_params)

        expect(rough_assignment.reload.updated_at).to be > original_time
      end
    end

    context 'with invalid parameters' do
      it 'fails when rough_assignment is missing' do
        result = described_class.call(**valid_params, rough_assignment: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Rough assignment is required')
      end

      it 'fails when administrator is missing' do
        result = described_class.call(**valid_params, administrator: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Administrator is required')
      end
    end

    context 'with authorization issues' do
      it 'fails when administrator is from different organization' do
        other_organization = create(:organization)
        other_admin = create(:user, organization: other_organization)

        result = described_class.call(**valid_params, administrator: other_admin)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Administrator must belong to same organization')
      end
    end

    context 'with wrong assignment status' do
      it 'fails when assignment is already confirmed' do
        confirmed_assignment = create(:assignment, :confirmed, project: project, member: member)

        result = described_class.call(**valid_params, rough_assignment: confirmed_assignment)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Assignment is not in rough status')
      end

      it 'fails when assignment is ongoing' do
        ongoing_assignment = create(:assignment, :ongoing, project: project, member: member)

        result = described_class.call(**valid_params, rough_assignment: ongoing_assignment)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Assignment is not in rough status')
      end
    end

    context 'with capacity constraints' do
      it 'fails when confirming would exceed member capacity' do
        # Create existing confirmed assignment that uses 60% capacity
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 2.weeks)
        create(:assignment, :confirmed,
               member: member,
               project: other_project,
               start_date: Date.current,
               end_date: Date.current + 1.week,
               allocation_percentage: 60.0)

        # Try to confirm rough assignment with 50% - total would be 110%
        result = described_class.call(**valid_params)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Confirming this assignment would exceed member capacity')
      end

      it 'succeeds when capacity is within limits' do
        # Create existing confirmed assignment that uses 40% capacity
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 2.weeks)
        create(:assignment, :confirmed,
               member: member,
               project: other_project,
               start_date: Date.current,
               end_date: Date.current + 1.week,
               allocation_percentage: 40.0)

        # Confirm rough assignment with 50% - total would be 90%
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data.status).to eq('confirmed')
      end

      it 'ignores other rough assignments when checking capacity' do
        # Create existing rough assignment that uses 60% capacity
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 2.weeks)
        create(:assignment, :rough,
               member: member,
               project: other_project,
               start_date: Date.current,
               end_date: Date.current + 1.week,
               allocation_percentage: 60.0)

        # Should succeed because rough assignments don't count toward capacity
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data.status).to eq('confirmed')
      end
    end
  end
end
