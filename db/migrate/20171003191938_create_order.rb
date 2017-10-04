class CreateOrder < ActiveRecord::Migration[5.1]
  def up
    create_table :orders do |t|
      t.string :order_id
      t.string :transaction_id
      t.string :charge_status
      t.string :payment_processor
      t.integer :address_is_active
      t.string :status
      t.string :type
      t.string :charge_id
      t.string :address_id
      t.string :shopify_id
      t.string :shopify_order_id
      t.string :shopify_order_number
      t.string :shopify_cart_token
      t.datetime :shipping_date
      t.datetime :scheduled_at
      t.datetime :shipped_date
      t.datetime :processed_at
      t.string :customer_id
      t.string :first_name
      t.string :last_name
      t.integer :is_prepaid
      t.datetime :created_at
      t.datetime :updated_at
      t.string :email
      t.jsonb :line_items
      t.decimal :total_price, precision: 10, scale: 2
      t.jsonb :shipping_address
      t.jsonb :billing_address



      

    end
    add_index :orders, :order_id
    add_index :orders, :transaction_id
    add_index :orders, :charge_id
    add_index :orders, :address_id
    add_index :orders, :shopify_id
    add_index :orders, :shopify_order_id
    add_index :orders, :shopify_order_number
    add_index :orders, :customer_id
    
    
    
  end

  def down
    remove_index :orders, :order_id
    remove_index :orders, :transaction_id
    remove_index :orders, :charge_id
    remove_index :orders, :address_id
    remove_index :orders, :shopify_id
    remove_index :orders, :shopify_order_id
    remove_index :orders, :shopify_order_number
    remove_index :orders, :customer_id
    drop_table :orders
    
  end



end
