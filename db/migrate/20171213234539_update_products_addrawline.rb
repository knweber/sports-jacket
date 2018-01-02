class UpdateProductsAddrawline < ActiveRecord::Migration[5.1]
  
  def up
    add_column :subscriptions_updated, :raw_line_items, :jsonb
    
  end

  def down
     remove_column :subscriptions_updated, :raw_line_items, :jsonb
    
  end



end
