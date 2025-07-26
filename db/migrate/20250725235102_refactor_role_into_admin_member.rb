class RefactorRoleIntoAdminMember < ActiveRecord::Migration[8.0]
  def change
    # Create admin_members table
    create_table :admin_members do |t|
      t.references :organization, null: false, foreign_key: true
      t.timestamps
    end

    # Remove role_id from members table
    remove_column :members, :role_id, :integer

    # Drop roles table (no data migration needed as this is a structural change)
    drop_table :roles do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
      t.index %i[organization_id name], unique: true
    end
  end
end
