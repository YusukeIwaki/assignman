require 'rails_helper'

RSpec.describe Member do
  describe 'validations' do
    let(:organization) { create(:organization) }

    it 'validates presence of name' do
      member = build(:member, name: nil, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of capacity' do
      member = build(:member, capacity: nil, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:capacity]).to include("can't be blank")
    end

    it 'validates capacity is greater than 0' do
      member = build(:member, capacity: 0, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:capacity]).to include('must be greater than 0')
    end

    it 'validates capacity is less than or equal to 200' do
      member = build(:member, capacity: 250, organization: organization)
      expect(member).not_to be_valid
      expect(member.errors[:capacity]).to include('must be less than or equal to 200')
    end

    it 'allows valid capacity' do
      member = build(:member, capacity: 100, organization: organization)
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
end
