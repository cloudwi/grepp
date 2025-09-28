class CreateTestRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :test_registrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :test, null: false, foreign_key: true

      t.timestamps
    end
  end
end
