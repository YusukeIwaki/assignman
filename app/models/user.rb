# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class User < ApplicationRecord
  has_one :user_credential, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_one :admin, dependent: :destroy

  delegate :email, to: :user_credential, allow_nil: true
  delegate :name, to: :user_profile, allow_nil: true
end
