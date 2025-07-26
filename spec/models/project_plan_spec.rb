require 'rails_helper'

RSpec.describe ProjectPlan do
  around do |example|
    travel_to Date.new(2024, 1, 1) do
      example.run
    end
  end
  describe 'validations' do
    let(:standard_project) { create(:standard_project) }

    it 'validates uniqueness of standard_project_id' do
      # Standard project already has a project plan created automatically
      duplicate = build(:project_plan, standard_project: standard_project)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:standard_project_id]).to include('has already been taken')
    end
  end

  describe 'associations' do
    let(:standard_project) { create(:standard_project) }
    let(:project_plan) { standard_project.project_plan }

    it 'belongs to standard_project' do
      expect(project_plan).to respond_to(:standard_project)
    end

    it 'has many rough_project_assignments through standard_project' do
      expect(project_plan).to respond_to(:rough_project_assignments)
    end

    it 'has many detailed_project_assignments through standard_project' do
      expect(project_plan).to respond_to(:detailed_project_assignments)
    end
  end

  describe '#total_rough_hours' do
    let(:standard_project) { create(:standard_project) }
    let(:project_plan) { standard_project.project_plan }

    context 'with no rough assignments' do
      it 'returns 0' do
        expect(project_plan.total_rough_hours).to eq(0)
      end
    end

    context 'with rough assignments' do
      let!(:assignment1) { create(:rough_project_assignment, standard_project: standard_project, scheduled_hours: 40.0) }
      let!(:assignment2) { create(:rough_project_assignment, standard_project: standard_project, scheduled_hours: 20.0) }

      it 'sums all rough assignment hours' do
        expect(project_plan.total_rough_hours).to eq(60.0)
      end
    end
  end

  describe '#total_detailed_hours' do
    let(:standard_project) { create(:standard_project) }
    let(:project_plan) { standard_project.project_plan }

    context 'with no detailed assignments' do
      it 'returns 0' do
        expect(project_plan.total_detailed_hours).to eq(0)
      end
    end

    context 'with detailed assignments' do
      let!(:assignment1) { create(:detailed_project_assignment, standard_project: standard_project, scheduled_hours: 80.0) }
      let!(:assignment2) { create(:detailed_project_assignment, standard_project: standard_project, scheduled_hours: 40.0) }

      it 'sums all detailed assignment hours' do
        expect(project_plan.total_detailed_hours).to eq(120.0)
      end
    end
  end

  describe '#budget_remaining' do
    let(:standard_project) { create(:standard_project, budget_hours: 200.0) }
    let(:project_plan) { standard_project.project_plan }

    context 'when project has no budget_hours' do
      let(:standard_project) { create(:standard_project, budget_hours: nil) }

      it 'returns nil' do
        expect(project_plan.budget_remaining).to be_nil
      end
    end

    context 'when project has budget_hours' do
      let!(:rough_assignment) { create(:rough_project_assignment, standard_project: standard_project, scheduled_hours: 50.0) }
      let!(:detailed_assignment) { create(:detailed_project_assignment, standard_project: standard_project, scheduled_hours: 80.0) }

      it 'calculates remaining budget correctly' do
        expect(project_plan.budget_remaining).to eq(70.0)
      end
    end
  end

  describe '#convert_rough_to_detailed' do
    let(:standard_project) { create(:standard_project, start_date: Date.new(2024, 1, 8), end_date: Date.new(2024, 2, 8)) }
    let(:project_plan) { standard_project.project_plan }
    let(:member) { create(:member, organization: standard_project.organization, standard_working_hours: 40.0) }
    let(:rough_assignment) do
      create(:rough_project_assignment,
             standard_project: standard_project,
             member: member,
             start_date: Date.new(2024, 1, 8),
             end_date: Date.new(2024, 1, 12),
             scheduled_hours: 16.0)  # 4 hours per day for 4 working days
    end

    it 'creates a detailed assignment from rough assignment' do
      expect do
        project_plan.convert_rough_to_detailed(rough_assignment)
      end.to change(DetailedProjectAssignment, :count).by(1)
    end

    it 'deletes the rough assignment' do
      rough_assignment # Create the assignment
      initial_count = RoughProjectAssignment.count
      
      result = project_plan.convert_rough_to_detailed(rough_assignment)
      
      expect(result).not_to be_nil
      expect(RoughProjectAssignment.count).to eq(initial_count - 1)
    end

    it 'preserves assignment attributes' do
      detailed = project_plan.convert_rough_to_detailed(rough_assignment)
      expect(detailed.member).to eq(member)
      expect(detailed.start_date).to eq(rough_assignment.start_date)
      expect(detailed.end_date).to eq(rough_assignment.end_date)
      expect(detailed.scheduled_hours).to eq(rough_assignment.scheduled_hours)
    end

    context 'when rough assignment belongs to different project' do
      let(:other_project) { create(:standard_project) }
      let(:other_assignment) { create(:rough_project_assignment, standard_project: other_project) }

      it 'returns nil' do
        expect(project_plan.convert_rough_to_detailed(other_assignment)).to be_nil
      end
    end
  end
end