# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_name  (name) UNIQUE
#
class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :skills, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
