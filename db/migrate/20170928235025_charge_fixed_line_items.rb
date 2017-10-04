class ChargeFixedLineItems < ActiveRecord::Migration[5.1]
  def up
    create_table :charge_fixed_line_items do |t|
      t.string :charge_id
      t.integer :grams
      t.decimal :price, precision: 10, scale: 2
      t.integer :quantity
      t.string :shopify_product_id
      t.string :shopify_variant_id
      t.string :sku
      t.string :subscription_id
      t.string :title
      t.string :variant_title
      t.string :vendor


      
    end
    add_index :charge_fixed_line_items, :charge_id

  end

  def down
    remove_index :charge_fixed_line_items, :charge_id
    drop_table :charge_fixed_line_items
    
  end
end
