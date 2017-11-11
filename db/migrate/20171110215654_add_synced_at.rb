class AddSyncedAt < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :synced_at, :timestamp
    add_column :orders, :synced_at, :timestamp
    add_column :charges, :synced_at, :timestamp
    add_column :customers, :synced_at, :timestamp
  end
end
