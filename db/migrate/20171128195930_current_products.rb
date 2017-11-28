class CurrentProducts < ActiveRecord::Migration[5.1]
  def up
    create_table :current_products do |t|
      t.string :prod_id_key
      t.string :prod_id_value
      
     
      
    end
    add_index :current_products, :prod_id_key 
    add_index :current_products, :prod_id_value   
  end

  def down
    remove_index :current_products, :prod_id_key
    remove_index :current_products, :prod_id_value
    drop_table :current_products
    
    
  end



end
