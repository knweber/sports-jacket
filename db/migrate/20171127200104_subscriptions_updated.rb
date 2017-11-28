class SubscriptionsUpdated < ActiveRecord::Migration[5.1]
  def up
    create_table :subscriptions_updated do |t|
      t.string :subscription_id
      t.string :customer_id
      t.datetime :updated_at
      t.datetime :next_charge_scheduled_at
      t.string :product_title
      t.string :status
      t.string :sku
      t.string :shopify_product_id
      t.string :shopify_variant_id
      t.boolean :updated, default: false
      t.datetime :processed_at
     
      
    end
    add_index :subscriptions_updated, :subscription_id 
    add_index :subscriptions_updated, :customer_id   
  end

  def down
    remove_index :subscriptions_updated, :subscription_id 
    remove_index :subscriptions_updated, :customer_id 
    drop_table :subscriptions_updated
    
    
  end


end
