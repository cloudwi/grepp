class CreateCourseRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :course_registrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
