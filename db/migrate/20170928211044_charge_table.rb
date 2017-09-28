class ChargeTable < ActiveRecord::Migration[5.1]
  def up
    create_table :charges do |t|
      t.string :address_id
      t.jsonb :billing_address
      t.jsonb :client_details
      t.datetime :created_at
      t.string :customer_hash
      t.string :customer_id
      t.string :first_name
      t.string :charge_id
      t.string :last_name
      t.jsonb :line_items
      t.string :note
      t.jsonb :note_attributes
      t.datetime :processed_at
      t.datetime :scheduled_at
      t.integer :shipments_count
      t.jsonb :shipping_address
      t.string :shopify_order_id
      t.string :status
      t.decimal :sub_total, precision: 10, scale: 2
      t.decimal :sub_total_price, precision: 10, scale: 2
      t.string :tags
      t.decimal :tax_lines, precision: 10, scale: 2
      t.decimal :total_discounts, precision: 10, scale: 2
      t.decimal :total_line_items_price, precision: 10, scale: 2
      t.decimal :total_tax, precision: 10, scale: 2
      t.integer :total_weight


      t.decimal :total_price, precision: 10, scale: 2
      t.datetime :updated_at

      

    end
  end

  def down
    drop_table :charges
  end



end
