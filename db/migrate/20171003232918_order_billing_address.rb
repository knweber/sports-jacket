class OrderBillingAddress < ActiveRecord::Migration[5.1]
  def up
    create_table :order_billing_address do |t|
      t.string :order_id
      t.string :province
      t.string :city
      t.string :first_name
      t.string :last_name
      t.string :zip
      t.string :country
      t.string :address1
      t.string :address2
      t.string :company
      t.string :phone
      
    end
    add_index :order_billing_address, :order_id    
  end

  def down
    remove_index :order_billing_address, :order_id 
    drop_table :order_billing_address
    
    
  end


end
