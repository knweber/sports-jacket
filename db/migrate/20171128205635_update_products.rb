class UpdateProducts < ActiveRecord::Migration[5.1]
  def up
    create_table :update_products do |t|
      t.string :sku
      t.string :product_title
      t.string :shopify_product_id
      t.string :shopify_variant_id
      
     
      
    end
    add_index :update_products, :sku 
    add_index :update_products, :product_title   
    add_index :update_products, :shopify_product_id
    add_index :update_products, :shopify_variant_id
  end

  def down
    remove_index :update_products, :sku 
    remove_index :update_products, :product_title   
    remove_index :update_products, :shopify_product_id
    remove_index :update_products, :shopify_variant_id
    drop_table :update_products
    
    
  end
end
