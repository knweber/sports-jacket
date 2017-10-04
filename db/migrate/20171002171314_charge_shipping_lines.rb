class ChargeShippingLines < ActiveRecord::Migration[5.1]
  def up
    create_table :charges_shipping_lines do |t|
      t.string :charge_id
      t.string :code
      t.decimal :price, precision: 10, scale: 2
      t.string :source
      t.string :title
      t.jsonb :tax_lines
      t.string :carrier_identifier
      t.string :request_fulfillment_service_id
      

      
    end
    add_index :charges_shipping_lines, :charge_id

  end

  def down
    remove_index :charges_shipping_lines, :charge_id
    drop_table :charges_shipping_lines
    
  end
end
