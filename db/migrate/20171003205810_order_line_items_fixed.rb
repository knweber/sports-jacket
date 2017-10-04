class OrderLineItemsFixed < ActiveRecord::Migration[5.1]
  def up
    create_table :order_line_items_fixed do |t|
      t.string :order_id
      t.string :shopify_variant_id
      t.string :title
      t.string :variant_title
      t.string :subscription_id
      t.integer :quantity
      t.string :shopify_product_id
      t.string :product_title
      


      

    end
    add_index :order_line_items_fixed, :order_id
    add_index :order_line_items_fixed, :subscription_id  
    
    
  end

  def down
    remove_index :order_line_items_fixed, :order_id
    remove_index :order_line_items_fixed, :subscription_id
    drop_table :order_line_items_fixed
    
    
  end



end
