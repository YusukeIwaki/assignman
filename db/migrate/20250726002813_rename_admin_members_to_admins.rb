class RenameAdminMembersToAdmins < ActiveRecord::Migration[8.0]
  def change
    rename_table :admin_members, :admins
  end
end
