require 'rails_helper'

RSpec.describe CreateOngoingAssignment do
  let(:organization) { create(:organization) }
  let(:administrator) { create(:user, organization: organization) }
  let(:project) { create(:project, organization: organization) }
  let(:member) { create(:member, organization: organization, capacity: 100.0) }

  describe '#call' do
    let(:valid_params) do
      {
        project: project,
        member: member,
        start_date: Date.current,
        end_date: Date.current + 6.months,
        allocation_percentage: 30.0,
        administrator: administrator
      }
    end

    context 'with valid parameters' do
      it 'creates ongoing assignment successfully' do
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data).to be_a(Assignment)
        expect(result.data.status).to eq('ongoing')
        expect(result.data.project).to eq(project)
        expect(result.data.member).to eq(member)
        expect(result.data.allocation_percentage).to eq(30.0)
      end

      it 'saves the assignment to database' do
        expect { described_class.call(**valid_params) }.to change(Assignment, :count).by(1)

        assignment = Assignment.last
        expect(assignment.status).to eq('ongoing')
        expect(assignment.project).to eq(project)
        expect(assignment.member).to eq(member)
      end
    end

    context 'with indefinite end date' do
      it 'creates ongoing assignment without end_date' do
        result = described_class.call(**valid_params, end_date: nil)

        expect(result.success?).to be true
        expect(result.data.end_date).to be_nil
        expect(result.data.status).to eq('ongoing')
      end
    end

    context 'with invalid parameters' do
      it 'fails when project is missing' do
        result = described_class.call(**valid_params, project: nil)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Project is required')
      end

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

      it 'fails when project and member are from different organizations' do
        other_organization = create(:organization)
        other_member = create(:member, organization: other_organization)

        result = described_class.call(**valid_params, member: other_member)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Project and member must belong to same organization')
      end
    end

    context 'with capacity constraints' do
      it 'fails when assignment would exceed member capacity' do
        # Create existing confirmed assignment that uses 80% capacity
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 3.months)
        create(:assignment, :confirmed,
               member: member,
               project: other_project,
               start_date: Date.current,
               end_date: Date.current + 1.month,
               allocation_percentage: 80.0)

        # Try to create ongoing assignment with 30% - total would be 110%
        result = described_class.call(**valid_params)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Assignment would exceed member capacity')
      end

      it 'succeeds when capacity is within limits' do
        # Create existing confirmed assignment that uses 60% capacity
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 3.months)
        create(:assignment, :confirmed,
               member: member,
               project: other_project,
               start_date: Date.current,
               end_date: Date.current + 1.month,
               allocation_percentage: 60.0)

        # Create ongoing assignment with 30% - total would be 90%
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data.status).to eq('ongoing')
      end

      it 'handles indefinite ongoing assignments correctly' do
        # Create existing indefinite ongoing assignment
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 2.weeks)
        create(:assignment, :ongoing,
               member: member,
               project: other_project,
               start_date: Date.current - 1.month,
               end_date: nil,
               allocation_percentage: 50.0)

        # Try to create another ongoing assignment with 60% - should fail
        result = described_class.call(**valid_params, allocation_percentage: 60.0)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Assignment would exceed member capacity')
      end

      it 'ignores rough assignments when checking capacity' do
        # Create existing rough assignment that uses 80% capacity
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 2.weeks)
        create(:assignment, :rough,
               member: member,
               project: other_project,
               start_date: Date.current,
               end_date: Date.current + 1.month,
               allocation_percentage: 80.0)

        # Should succeed because rough assignments don't count toward capacity
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data.status).to eq('ongoing')
      end
    end
  end
end
