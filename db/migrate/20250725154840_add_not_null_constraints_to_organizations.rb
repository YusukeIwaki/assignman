class AddNotNullConstraintsToOrganizations < ActiveRecord::Migration[8.0]
  def change
    change_column_null :organizations, :name, false
    add_index :organizations, :name, unique: true
    
    change_column_null :members, :name, false
    change_column_null :members, :capacity, false
    change_column_default :members, :capacity, from: nil, to: 100.0
    change_column :members, :capacity, :decimal, precision: 5, scale: 1
    
    change_column_null :projects, :name, false
    change_column_null :projects, :start_date, false
    change_column_null :projects, :end_date, false
    change_column_null :projects, :status, false
    change_column_default :projects, :status, from: nil, to: "tentative"
    change_column :projects, :budget, :decimal, precision: 15, scale: 2
    
    change_column_null :roles, :name, false
    add_index :roles, [:organization_id, :name], unique: true
    
    change_column_null :skills, :name, false
    add_index :skills, [:organization_id, :name], unique: true
    
    change_column_null :assignments, :start_date, false
    change_column_null :assignments, :end_date, false
    change_column_null :assignments, :allocation_percentage, false
    change_column_default :assignments, :allocation_percentage, from: nil, to: 100.0
    change_column :assignments, :allocation_percentage, :decimal, precision: 5, scale: 1
    
    add_index :member_skills, [:member_id, :skill_id], unique: true
  end
end
