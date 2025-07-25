# == Schema Information
#
# Table name: user_profiles
#
#  id         :integer          not null, primary key
#  avatar_url :string
#  bio        :text
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class UserProfile < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
end
