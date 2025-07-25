class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :allocation_percentage

      t.timestamps
    end
  end
end
