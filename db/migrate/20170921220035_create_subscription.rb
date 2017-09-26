class CreateSubscription < ActiveRecord::Migration[5.1]
  def up
    create_table :subscriptions do |t|
      t.string :subscription_id
      t.string :address_id
      t.string :customer_id
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :next_charge_scheduled_at
      t.datetime :cancelled_at
      t.string :product_title
      t.decimal :price, precision: 10, scale: 2
      t.integer :quantity
      t.string :status
      t.string :shopify_product_id
      t.string :shopify_variant_id
      t.string :sku
      t.string :order_interval_unit
      t.integer :order_interval_frequency
      t.integer :charge_interval_frequency
      t.integer :order_day_of_month
      t.integer :order_day_of_week      


    end
  end

  def down
    drop_table :subscriptions
  end
end
