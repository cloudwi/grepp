class AddCompletedAtToRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :test_registrations, :completed_at, :timestamp, null: true unless column_exists?(:test_registrations, :completed_at)
    add_column :course_registrations, :completed_at, :timestamp, null: true unless column_exists?(:course_registrations, :completed_at)
  end
end