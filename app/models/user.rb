# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_users_on_organization_id  (organization_id)
#
class User < ApplicationRecord
  belongs_to :organization
  has_one :user_credential, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_one :admin, dependent: :destroy

  delegate :email, to: :user_credential, allow_nil: true
  delegate :name, to: :user_profile, allow_nil: true
end
