class AddCancelledAtToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :cancelled_at, :timestamp, null: true unless column_exists?(:payments, :cancelled_at)
  end
end