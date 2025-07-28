require 'rails_helper'

RSpec.describe CreateRoughProjectAssignment do
  around do |example|
    travel_to Date.new(2024, 1, 1) do
      example.run
    end
  end

  let(:admin) { create(:admin) }
  let(:member) { create(:member) }
  let(:standard_project) { create(:standard_project) }
  let(:start_date) { Date.new(2024, 1, 8) }
  let(:end_date) { Date.new(2024, 2, 8) }
  let(:scheduled_hours) { 80.0 }

  subject(:use_case) { described_class.new }

  describe '#call' do
    let(:params) do
      {
        standard_project: standard_project,
        member: member,
        start_date: start_date,
        end_date: end_date,
        scheduled_hours: scheduled_hours,
        admin: admin
      }
    end

    context 'with valid inputs' do
      it 'creates a rough project assignment' do
        expect { use_case.call(**params) }.to change(RoughProjectAssignment, :count).by(1)
      end

      it 'returns success' do
        result = use_case.call(**params)
        expect(result).to be_success
        expect(result.data).to be_a(RoughProjectAssignment)
        expect(result.data.member).to eq(member)
        expect(result.data.standard_project).to eq(standard_project)
        expect(result.data.scheduled_hours).to eq(scheduled_hours)
      end
    end

    context 'with invalid inputs' do
      context 'when required parameters are missing' do
        it 'fails when project is missing' do
          params[:standard_project] = nil
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

        it 'fails when scheduled_hours is missing' do
          params[:scheduled_hours] = nil
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Scheduled hours is required')
        end
      end


      context 'when overlapping rough assignment exists' do
        let!(:existing_assignment) do
          create(:rough_project_assignment,
                 member: member,
                 start_date: start_date - 1.week,
                 end_date: end_date + 1.week)
        end

        it 'fails to create overlapping assignment' do
          result = use_case.call(**params)
          expect(result).to be_failure
          expect(result.error.message).to eq('Member already has overlapping rough assignment')
        end
      end
    end

  end
end