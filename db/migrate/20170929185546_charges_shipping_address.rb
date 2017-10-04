class ChargesShippingAddress < ActiveRecord::Migration[5.1]
  def up
    create_table :charges_shipping_address do |t|
      t.string :charge_id
      t.string :address1
      t.string :address2
      t.string :city
      t.string :company
      t.string :country
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :province
      t.string :zip
      

      
    end
    add_index :charges_shipping_address, :charge_id

  end

  def down
    remove_index :charges_shipping_address, :charge_id
    drop_table :charges_shipping_address
    
  end


end
