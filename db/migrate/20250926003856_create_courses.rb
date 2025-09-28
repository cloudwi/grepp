class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :title
      t.datetime :enrollment_start_date
      t.datetime :enrollment_end_date

      t.timestamps
    end
  end
end
