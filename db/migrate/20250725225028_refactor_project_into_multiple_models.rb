class RefactorProjectIntoMultipleModels < ActiveRecord::Migration[8.0]
  def up
    # First, create the new project tables
    create_table :standard_projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: 'tentative' # tentative, confirmed, archived
      t.string :client_name
      t.decimal :budget, precision: 15, scale: 2
      t.text :notes
      t.timestamps
    end

    create_table :ongoing_projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: 'active' # active, inactive
      t.string :client_name
      t.decimal :budget, precision: 15, scale: 2
      t.text :notes
      t.timestamps
    end

    # Update assignment table foreign keys to reference the new tables
    add_reference :rough_project_assignments, :standard_project, foreign_key: true
    add_reference :detailed_project_assignments, :standard_project, foreign_key: true
    add_reference :ongoing_assignments, :ongoing_project, foreign_key: true

    # Now drop the old project_id columns and the projects table
    remove_reference :rough_project_assignments, :project, foreign_key: true
    remove_reference :detailed_project_assignments, :project, foreign_key: true
    remove_reference :ongoing_assignments, :project, foreign_key: true

    drop_table :projects
  end

  def down
    # Re-create the projects table
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: 'tentative'
      t.string :client_name
      t.decimal :budget, precision: 15, scale: 2
      t.text :notes
      t.timestamps
    end

    # Add back project_id references
    add_reference :rough_project_assignments, :project, foreign_key: true
    add_reference :detailed_project_assignments, :project, foreign_key: true
    add_reference :ongoing_assignments, :project, foreign_key: true

    # Remove new project type references
    remove_reference :rough_project_assignments, :standard_project, foreign_key: true
    remove_reference :detailed_project_assignments, :standard_project, foreign_key: true
    remove_reference :ongoing_assignments, :ongoing_project, foreign_key: true

    # Drop the new tables
    drop_table :ongoing_projects
    drop_table :standard_projects
  end
end
