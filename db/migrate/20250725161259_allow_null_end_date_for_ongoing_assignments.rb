class AllowNullEndDateForOngoingAssignments < ActiveRecord::Migration[8.0]
  def change
    change_column_null :assignments, :end_date, true
  end
end
