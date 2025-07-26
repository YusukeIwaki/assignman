# == Schema Information
#
# Table name: admins
#
#  id              :integer          not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#  user_id         :integer
#
# Indexes
#
#  index_admins_on_organization_id  (organization_id)
#  index_admins_on_user_id          (user_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#  user_id          (user_id => users.id)
#
class Admin < ApplicationRecord
  belongs_to :organization
  belongs_to :user, optional: true

  delegate :email, :name, to: :user, allow_nil: true
end
