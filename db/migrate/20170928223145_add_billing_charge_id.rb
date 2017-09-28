class AddBillingChargeId < ActiveRecord::Migration[5.1]
  def up 
    add_column :charge_billing_address, :charge_id, :string
    
  end

  def down
    remove_column :charge_billing_address, :charge_id, :string
  end
end
