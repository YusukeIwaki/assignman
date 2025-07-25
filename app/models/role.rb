# == Schema Information
#
# Table name: roles
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_roles_on_organization_id           (organization_id)
#  index_roles_on_organization_id_and_name  (organization_id,name) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
class Role < ApplicationRecord
  belongs_to :organization
  has_many :members, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :organization_id }
end
