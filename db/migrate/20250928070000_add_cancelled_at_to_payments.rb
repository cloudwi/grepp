class AddCancelledAtToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :cancelled_at, :timestamp, null: true
  end
end