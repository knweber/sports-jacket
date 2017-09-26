class ChangeUpdateLineItems < ActiveRecord::Migration[5.1]
  def up 
    change_column :update_line_items, :properties, 'jsonb USING CAST(properties AS jsonb)'
    
  end

  def down
    change_column :update_line_items, :properties, :string
  end
end
