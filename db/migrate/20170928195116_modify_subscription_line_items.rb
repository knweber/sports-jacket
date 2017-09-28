class ModifySubscriptionLineItems < ActiveRecord::Migration[5.1]
  def up
    change_column :subscriptions, :raw_line_item_properties, 'jsonb USING CAST(raw_line_item_properties AS jsonb)'
  end

  def down
    change column :subscriptions, :raw_line_item_properties, :json

  end


end
