class RefactorAssignmentIntoMultipleModels < ActiveRecord::Migration[8.0]
  def change
    # Drop the existing assignments table
    drop_table :assignments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :allocation_percentage, precision: 5, scale: 1
      t.string :status, null: false, default: 'confirmed'
      t.timestamps
      t.index :status
    end

    # Create rough_project_assignments table
    create_table :rough_project_assignments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :allocation_percentage, precision: 5, scale: 1, null: false, default: 100.0
      t.timestamps
    end

    # Create detailed_project_assignments table
    create_table :detailed_project_assignments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :allocation_percentage, precision: 5, scale: 1, null: false, default: 100.0
      t.timestamps
    end

    # Create ongoing_assignments table
    create_table :ongoing_assignments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date # nullable for indefinite assignments
      t.decimal :allocation_percentage, precision: 5, scale: 1, null: false, default: 100.0
      t.timestamps
    end
  end
end
