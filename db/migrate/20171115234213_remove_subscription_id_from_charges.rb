class RemoveSubscriptionIdFromCharges < ActiveRecord::Migration[5.1]
  def change
    remove_column :charges, :subscription_id, :string
  end
end
