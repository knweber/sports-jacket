class MatchingProducts < ActiveRecord::Migration[5.1]
  def up
    create_table :matching_products do |t|
      
      t.string :new_product_title
      t.string :incoming_product_id
      t.boolean :threepk, default: false
      t.string :outgoing_product_id
      
     
      
    end
    add_index :matching_products, :incoming_product_id 
    
  end

  def down
    remove_index :matching_products, :incoming_product_id
    drop_table :matching_products
    
    
  end


end
