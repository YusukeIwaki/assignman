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

    it 'belongs to role optionally' do
      expect(member).to respond_to(:role)
    end

    it 'has many assignments' do
      expect(member).to respond_to(:assignments)
    end

    it 'has many skills through member_skills' do
      expect(member).to respond_to(:skills)
    end
  end
end
