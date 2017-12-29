class AlternateProducts < ActiveRecord::Migration[5.1]
  def up
    create_table :alternate_products do |t|
      
      t.string :product_title
      t.string :product_id
      t.string :variant_id
      t.string :sku
      
     
      
    end
    add_index :alternate_products, :product_id 
    
  end

  def down
    remove_index :alternate_products, :product_id 
    drop_table :alternate_products
    
    
  end
  


end
