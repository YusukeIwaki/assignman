class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :role, null: false, default: 'viewer'
      t.integer :organization_id, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :organization_id
  end
end
