class AddExpireSubscription < ActiveRecord::Migration[5.1]
  def up
    add_column :subscriptions, :expire_after_specific_number_charges, :integer
    add_index :subscriptions, :expire_after_specific_number_charges 
  end

  def down
    remove_index :subscriptions, :expire_after_specific_number_charges
    remove_column :subscriptions, :expire_after_specific_number_charges, :integer
    
  end



end
