class AddCompletedAtToRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :test_registrations, :completed_at, :timestamp, null: true
    add_column :course_registrations, :completed_at, :timestamp, null: true
  end
end