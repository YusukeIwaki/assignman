class AddUserToAdminMembers < ActiveRecord::Migration[8.0]
  def change
    add_reference :admin_members, :user, null: true, foreign_key: true
  end
end
