require 'rails_helper'

RSpec.describe CreateRoughProjectAssignment do
  let(:organization) { create(:organization) }
  let(:administrator) { create(:user, organization: organization) }
  let(:project) { create(:project, organization: organization) }
  let(:member) { create(:member, organization: organization) }

  describe '#call' do
    let(:valid_params) do
      {
        project: project,
        member: member,
        start_date: Date.current,
        end_date: Date.current + 1.month,
        allocation_percentage: 50.0,
        administrator: administrator
      }
    end

    context 'with valid parameters' do
      it 'creates a rough assignment successfully' do
        result = described_class.call(**valid_params)

        expect(result.success?).to be true
        expect(result.data).to be_a(Assignment)
        expect(result.data.status).to eq('rough')
        expect(result.data.project).to eq(project)
        expect(result.data.member).to eq(member)
        expect(result.data.allocation_percentage).to eq(50.0)
      end

      it 'saves the assignment to database' do
        expect { described_class.call(**valid_params) }.to change(Assignment, :count).by(1)

        assignment = Assignment.last
        expect(assignment.status).to eq('rough')
        expect(assignment.project).to eq(project)
        expect(assignment.member).to eq(member)
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

    context 'with overlapping assignments' do
      it 'fails when member already has overlapping rough assignment' do
        # Create existing rough assignment
        create(:assignment, :rough,
               member: member,
               project: project,
               start_date: Date.current - 1.week,
               end_date: Date.current + 1.week)

        result = described_class.call(**valid_params)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Member already has overlapping rough assignment')
      end

      it 'succeeds when member has overlapping confirmed assignment' do
        # Create existing confirmed assignment (should not conflict with rough)
        other_project = create(:project, organization: organization,
                                         start_date: Date.current - 2.weeks,
                                         end_date: Date.current + 2.weeks)
        create(:assignment, :confirmed,
               member: member,
               project: other_project,
               start_date: Date.current - 1.week,
               end_date: Date.current + 1.week)

        result = described_class.call(**valid_params)

        expect(result.success?).to be true
      end
    end

    context 'with invalid assignment data' do
      it 'fails when end_date is before start_date' do
        result = described_class.call(**valid_params, start_date: Date.current + 1.month,
                                                      end_date: Date.current)

        expect(result.failure?).to be true
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to include('must be after start date')
      end
    end
  end
end
