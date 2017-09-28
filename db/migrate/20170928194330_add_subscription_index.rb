class AddSubscriptionIndex < ActiveRecord::Migration[5.1]
  def up
    add_index :subscriptions, :subscription_id
    add_index :subscriptions, :address_id
    add_index :subscriptions, :customer_id
    add_index :sub_line_items, :subscription_id
  end

  def down
    remove_index :subscriptions, :subscription_id
    remove_index :subscriptions, :address_id
    remove_index :subscriptions, :customer_id
    remove_index :sub_line_items, :subscription_id
  end
end
