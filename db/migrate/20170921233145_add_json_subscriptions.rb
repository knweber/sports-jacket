class AddJsonSubscriptions < ActiveRecord::Migration[5.1]
  def up 
    add_column :subscriptions, :raw_line_item_properties, :json
    
  end

  def down
    remove_column :subscriptions, :raw_line_item_properties, :json
  end
end
