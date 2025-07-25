require 'rails_helper'

RSpec.describe CreateOngoingAssignment do
  around do |example|
    travel_to Date.new(2024, 1, 1) do
      example.run
    end
  end

  let(:organization) { create(:organization) }
  let(:admin) { create(:admin, organization: organization) }
  let(:member) { create(:member, organization: organization, standard_working_hours: 40.0) }
  let(:ongoing_project) { create(:ongoing_project, organization: organization) }
  let(:start_date) { Date.new(2024, 1, 8) }
  let(:end_date) { nil }
  let(:weekly_scheduled_hours) { 20.0 }

  subject(:use_case) { described_class.new }

  describe '#call' do
    let(:params) do
      {
        ongoing_project: ongoing_project,
        member: member,
        start_date: start_date,
        end_date: end_date,
        weekly_scheduled_hours: weekly_scheduled_hours,
        admin: admin
      }
    end

    context 'with valid inputs' do
      it 'creates an ongoing assignment' do
        expect { use_case.call(**params) }.to change(OngoingAssignment, :count).by(1)
      end

      it 'returns success' do
        result = use_case.call(**params)
        expect(result).to be_success
        expect(result.data).to be_a(OngoingAssignment)
        expect(result.data.member).to eq(member)
        expect(result.data.ongoing_project).to eq(ongoing_project)
        expect(result.data.weekly_scheduled_hours).to eq(weekly_scheduled_hours)
      end

      context 'with end date' do
        let(:end_date) { Date.new(2024, 7, 8) }

        it 'creates assignment with end date' do
          result = use_case.call(**params)
          expect(result).to be_success
          expect(result.data.end_date).to eq(end_date)
        end
      end
    end

    context 'with invalid inputs' do
      context 'when required parameters are missing' do
        it 'fails when project is missing' do
          params[:ongoing_project] = nil
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Project is required')
        end

        it 'fails when member is missing' do
          params[:member] = nil
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Member is required')
        end

        it 'fails when weekly_scheduled_hours is missing' do
          params[:weekly_scheduled_hours] = nil
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Weekly scheduled hours is required')
        end
      end

      context 'when organizations do not match' do
        let(:other_organization) { create(:organization) }

        it 'fails when project belongs to different organization' do
          params[:ongoing_project] = create(:ongoing_project, organization: other_organization)
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Project and member must belong to same organization')
        end

        it 'fails when admin belongs to different organization' do
          params[:admin] = create(:admin, organization: other_organization)
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Admin must belong to same organization')
        end
      end

    end

    context 'authorization' do
      let(:other_organization) { create(:organization) }
      let(:unauthorized_admin) { create(:admin, organization: other_organization) }

      it 'fails when admin cannot manage the project' do
        other_project = create(:ongoing_project, organization: other_organization)
        other_member = create(:member, organization: other_organization)
        
        result = use_case.call(
          ongoing_project: other_project,
          member: other_member,
          start_date: start_date,
          end_date: end_date,
          weekly_scheduled_hours: weekly_scheduled_hours,
          admin: admin
        )
        
        expect(result).to be_failure
        expect(result.error).to be_a(BaseUseCase::ValidationError)
        expect(result.error.message).to eq('Admin must belong to same organization')
      end
    end
  end
end