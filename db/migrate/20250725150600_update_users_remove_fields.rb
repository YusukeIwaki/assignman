class UpdateUsersRemoveFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :email, :string
    remove_column :users, :name, :string
    remove_column :users, :role, :string
    remove_index :users, :email if index_exists?(:users, :email)
  end
end
