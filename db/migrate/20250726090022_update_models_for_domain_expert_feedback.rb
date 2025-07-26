class UpdateModelsForDomainExpertFeedback < ActiveRecord::Migration[8.0]
  def change
    # Update members table
    rename_column :members, :capacity, :standard_working_hours
    change_column :members, :standard_working_hours, :decimal, precision: 5, scale: 1, default: 40.0, null: false

    # Update standard_projects table
    rename_column :standard_projects, :budget, :budget_hours
    change_column :standard_projects, :budget_hours, :decimal, precision: 10, scale: 1

    # Update rough_project_assignments table
    rename_column :rough_project_assignments, :allocation_percentage, :scheduled_hours
    change_column :rough_project_assignments, :scheduled_hours, :decimal, precision: 5, scale: 1, null: false

    # Update detailed_project_assignments table
    rename_column :detailed_project_assignments, :allocation_percentage, :scheduled_hours
    change_column :detailed_project_assignments, :scheduled_hours, :decimal, precision: 5, scale: 1, null: false

    # Update ongoing_assignments table
    rename_column :ongoing_assignments, :allocation_percentage, :weekly_scheduled_hours
    change_column :ongoing_assignments, :weekly_scheduled_hours, :decimal, precision: 5, scale: 1, null: false

    # Create project_plans table
    create_table :project_plans do |t|
      t.references :standard_project, foreign_key: true, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
