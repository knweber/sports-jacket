class SkippableProducts < ActiveRecord::Migration[5.1]
  def up
    create_table :skippable_products do |t|
      
      t.string :product_title
      t.string :product_id
      t.boolean :threepk, default: false
      
     
      
    end
    add_index :skippable_products, :product_id 
    
  end

  def down
    remove_index :skippable_products, :product_id 
    drop_table :skippable_products
    
    
  end
  


end
