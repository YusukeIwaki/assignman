require 'rails_helper'

RSpec.describe Member do
  describe 'validations' do
    let(:organization) { create(:organization) }

    it 'validates presence of name' do
      member = build(:member, name: nil, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of standard_working_hours' do
      member = build(:member, standard_working_hours: nil, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:standard_working_hours]).to include("can't be blank")
    end

    it 'validates standard_working_hours is greater than 0' do
      member = build(:member, standard_working_hours: 0, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:standard_working_hours]).to include('must be greater than 0')
    end

    it 'validates standard_working_hours is less than or equal to 80' do
      member = build(:member, standard_working_hours: 100, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:standard_working_hours]).to include('must be less than or equal to 80')
    end

    it 'allows valid standard_working_hours' do
      member = build(:member, standard_working_hours: 40, organization: organization)
      expect(member).to be_valid
    end
  end

  describe 'associations' do
    let(:member) { create(:member) }

    it 'belongs to organization' do
      expect(member).to respond_to(:organization)
    end

    it 'has many rough_project_assignments' do
      expect(member).to respond_to(:rough_project_assignments)
    end

    it 'has many detailed_project_assignments' do
      expect(member).to respond_to(:detailed_project_assignments)
    end

    it 'has many ongoing_assignments' do
      expect(member).to respond_to(:ongoing_assignments)
    end

    it 'has many skills through member_skills' do
      expect(member).to respond_to(:skills)
    end
  end

  describe '#scheduled_hours_on_date' do
    let(:member) { create(:member, standard_working_hours: 40.0) }
    let(:today) { Date.new(2024, 1, 8) } # Monday

    around do |example|
      travel_to Date.new(2024, 1, 1) do
        example.run
      end
    end

    context 'with detailed project assignments' do
      let(:project) { create(:standard_project, organization: member.organization, start_date: today - 1.week, end_date: today + 1.month) }
      let!(:assignment) { create(:detailed_project_assignment, member: member, standard_project: project, scheduled_hours: 40.0, start_date: today, end_date: today + 4.days) }

      it 'calculates daily hours correctly' do
        expect(member.scheduled_hours_on_date(today)).to eq(8.0)
      end
    end

    context 'with ongoing assignments' do
      let!(:assignment) { create(:ongoing_assignment, member: member, weekly_scheduled_hours: 20.0, start_date: today) }

      it 'calculates daily hours correctly' do
        expect(member.scheduled_hours_on_date(today + 1.day)).to eq(4.0)
      end
    end

    context 'with both types of assignments' do
      let(:project) { create(:standard_project, organization: member.organization, start_date: today - 1.week, end_date: today + 1.month) }
      let!(:detailed) { create(:detailed_project_assignment, member: member, standard_project: project, scheduled_hours: 20.0, start_date: today, end_date: today + 4.days) }
      let!(:ongoing) { create(:ongoing_assignment, member: member, weekly_scheduled_hours: 10.0, start_date: today) }

      it 'sums hours correctly' do
        expect(member.scheduled_hours_on_date(today + 1.day)).to eq(6.0)
      end
    end
  end

  describe '#available_hours_on_date' do
    let(:member) { create(:member, standard_working_hours: 40.0) }
    let(:monday) { Date.new(2024, 1, 8) } # Monday

    around do |example|
      travel_to Date.new(2024, 1, 1) do
        example.run
      end
    end

    context 'on weekends' do
      it 'returns 0 for Saturday' do
        saturday = monday + 5.days
        expect(member.available_hours_on_date(saturday)).to eq(0)
      end

      it 'returns 0 for Sunday' do
        sunday = monday + 6.days
        expect(member.available_hours_on_date(sunday)).to eq(0)
      end
    end

    context 'on weekdays' do
      it 'returns full daily hours when no assignments' do
        expect(member.available_hours_on_date(monday)).to eq(8.0)
      end

      context 'with assignments' do
        let(:project) { create(:standard_project, organization: member.organization, start_date: monday - 1.week, end_date: monday + 1.month) }
        let!(:assignment) { create(:detailed_project_assignment, member: member, standard_project: project, scheduled_hours: 20.0, start_date: monday, end_date: monday + 4.days) }

        it 'returns remaining hours' do
          expect(member.available_hours_on_date(monday)).to eq(4.0)
        end
      end
    end
  end

  describe '#scheduled_hours_for_week' do
    let(:member) { create(:member, standard_working_hours: 40.0) }
    let(:week_start) { Date.new(2024, 1, 8) } # Monday

    around do |example|
      travel_to Date.new(2024, 1, 1) do
        example.run
      end
    end

    context 'with no assignments' do
      it 'returns 0' do
        expect(member.scheduled_hours_for_week(week_start)).to eq(0)
      end
    end

    context 'with assignments' do
      let(:project) { create(:standard_project, organization: member.organization, start_date: week_start - 1.week, end_date: week_start + 1.month) }
      let!(:assignment) { create(:detailed_project_assignment, member: member, standard_project: project, scheduled_hours: 40.0, start_date: week_start, end_date: week_start + 4.days) }

      it 'calculates weekly hours correctly' do
        expect(member.scheduled_hours_for_week(week_start)).to eq(40.0)
      end
    end
  end
end
