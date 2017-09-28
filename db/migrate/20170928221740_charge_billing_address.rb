class ChargeBillingAddress < ActiveRecord::Migration[5.1]
  def up
    create_table :charge_billing_address do |t|
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

  end

  def down
    drop_table :charge_billing_address
  end

end
