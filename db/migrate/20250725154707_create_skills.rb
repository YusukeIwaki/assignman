class CreateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :skills do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
