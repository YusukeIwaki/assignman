class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.decimal :capacity
      t.integer :role_id

      t.timestamps
    end
  end
end
