class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.integer :amount
      t.string :payment_method
      t.string :status
      t.datetime :payment_time
      t.datetime :cancelled_at
      t.references :user, null: false, foreign_key: true
      t.references :payable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
