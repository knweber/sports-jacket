class AddIndexChargeAddress < ActiveRecord::Migration[5.1]
  def up
    add_index :charge_billing_address, :charge_id
    
    
  end

  def down
    remove_index :charge_billing_address, :charge_id
    
    
  end
end
