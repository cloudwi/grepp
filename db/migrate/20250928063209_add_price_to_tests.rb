class AddPriceToTests < ActiveRecord::Migration[8.0]
  def change
    add_column :tests, :price, :decimal, precision: 10, scale: 2, null: true

    # Set default price for existing tests
    Test.update_all(price: 30000)

    # Now make it non-nullable
    change_column_null :tests, :price, false
  end
end
