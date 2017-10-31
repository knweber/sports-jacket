class CreateCustomerInfo < ActiveRecord::Migration[5.1]
  def up
    create_table :customer_info do |t|
      t.string :shopify_id
      t.string :subscription_id
    end
    add_index :customer_info, :shopify_id 
    add_index :customer_info, :subscription_id 
  end

  def down
    remove_index :customer_info, :shopify_id 
    remove_index :customer_info, :subscription_id 
    drop_table :customer_info
  end
end
