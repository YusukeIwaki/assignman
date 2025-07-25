require 'rails_helper'

RSpec.describe Project do
  describe 'validations' do
    let(:organization) { create(:organization) }

    it 'validates presence of name' do
      project = build(:project, name: nil, organization: organization)
      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of start_date' do
      project = build(:project, start_date: nil, organization: organization)
      expect(project).not_to be_valid
      expect(project.errors[:start_date]).to include("can't be blank")
    end

    it 'validates presence of end_date' do
      project = build(:project, end_date: nil, organization: organization)
      expect(project).not_to be_valid
      expect(project.errors[:end_date]).to include("can't be blank")
    end

    it 'validates end_date is after start_date' do
      project = build(:project,
                      start_date: Date.current + 1.day,
                      end_date: Date.current,
                      organization: organization)
      expect(project).not_to be_valid
      expect(project.errors[:end_date]).to include('must be after start date')
    end

    it 'validates status inclusion' do
      expect do
        build(:project, status: 'invalid', organization: organization)
      end.to raise_error(ArgumentError, "'invalid' is not a valid status")
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(described_class.statuses).to eq({
                                               'tentative' => 'tentative',
                                               'confirmed' => 'confirmed',
                                               'archived' => 'archived'
                                             })
    end
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }
    let!(:tentative_project) { create(:project, status: 'tentative', organization: organization) }
    let!(:confirmed_project) { create(:project, status: 'confirmed', organization: organization) }
    let!(:archived_project) { create(:project, status: 'archived', organization: organization) }

    it 'active scope returns non-archived projects' do
      active_projects = described_class.active
      expect(active_projects).to include(tentative_project, confirmed_project)
      expect(active_projects).not_to include(archived_project)
    end
  end
end
