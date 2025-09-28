class AddPriceToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :price, :decimal, precision: 10, scale: 2, null: true

    # Set default price for existing courses
    Course.update_all(price: 50000)

    # Now make it non-nullable
    change_column_null :courses, :price, false
  end
end
