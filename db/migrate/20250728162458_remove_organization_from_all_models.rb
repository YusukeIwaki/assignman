class RemoveOrganizationFromAllModels < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign keys first (users table doesn't have a foreign key)
    remove_foreign_key :members, :organizations
    remove_foreign_key :admins, :organizations
    remove_foreign_key :standard_projects, :organizations
    remove_foreign_key :ongoing_projects, :organizations
    remove_foreign_key :skills, :organizations
    
    # Remove organization_id columns
    remove_column :users, :organization_id, :integer
    remove_column :members, :organization_id, :integer
    remove_column :admins, :organization_id, :integer
    remove_column :standard_projects, :organization_id, :integer
    remove_column :ongoing_projects, :organization_id, :integer
    remove_column :skills, :organization_id, :integer
    
    # Drop organizations table
    drop_table :organizations
  end
end
