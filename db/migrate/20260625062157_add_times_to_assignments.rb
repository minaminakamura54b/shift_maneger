class AddTimesToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :start_time, :time
    add_column :assignments, :end_time, :time
  end
end
