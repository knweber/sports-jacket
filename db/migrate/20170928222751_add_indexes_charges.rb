class AddIndexesCharges < ActiveRecord::Migration[5.1]
  def up
    add_index :charges, :address_id
    add_index :charges, :customer_id
    add_index :charges, :charge_id
    
  end

  def down
    remove_index :charges, :address_id
    remove_index :charges, :customer_id
    remove_index :charges, :customer_id
    
  end


end
