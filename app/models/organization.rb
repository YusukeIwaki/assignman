class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :skills, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
end
