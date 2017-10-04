class CreateCustomer < ActiveRecord::Migration[5.1]
  def up
    create_table :customers do |t|
      t.string :customer_id
      t.string :hash
      t.string :shopify_customer_id
      t.string :email
      t.datetime :created_at
      t.datetime :updated_at
      t.string :first_name
      t.string :last_name
      t.string :billing_address1
      t.string :billing_address2
      t.string :billing_zip
      t.string :billing_city
      t.string :billing_company
      t.string :billing_province
      t.string :billing_country
      t.string :billing_phone
      t.string :processor_type
      t.string :status
      
    end
    add_index :customers, :customer_id 
    add_index :customers, :shopify_customer_id   
  end

  def down
    remove_index :customers, :customer_id 
    remove_index :customers, :shopify_customer_id
    drop_table :customers
    
    
  end


end
