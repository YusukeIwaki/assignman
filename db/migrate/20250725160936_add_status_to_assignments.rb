class AddStatusToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :status, :string, null: false, default: 'confirmed'
    add_index :assignments, :status
  end
end
