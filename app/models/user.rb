class User < ApplicationRecord
  validates :organization_id, presence: true
  
  has_one :user_credential, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  
  delegate :email, to: :user_credential, allow_nil: true
  delegate :name, to: :user_profile, allow_nil: true
end
