class SubscriptionProductUpdate < ActiveRecord::Migration[5.1]
  def up
    create_table :subscription_update do |t|
      t.string :subscription_id
      t.string :customer_id
      t.string :first_name
      t.string :last_name
      t.string :product_title
      t.string :shopify_product_id
      t.string :shopify_variant_id
      t.string :sku
      t.boolean :updated, :default => false
      t.datetime :updated_at
    end
    add_index :subscription_update, :subscription_id 
    add_index :subscription_update, :customer_id 
  end

  def down
    remove_index :subscription_update, :subscription_id  
    remove_index :subscription_update, :customer_id
    drop_table :subscription_update
  end


end
