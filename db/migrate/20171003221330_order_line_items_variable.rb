class OrderLineItemsVariable < ActiveRecord::Migration[5.1]
  def up
    create_table :order_line_items_variable do |t|
      t.string :order_id
      t.string :name
      t.string :value
    end
    add_index :order_line_items_variable, :order_id    
  end

  def down
    remove_index :order_line_items_variable, :order_id
    drop_table :order_line_items_variable
    
    
  end


end
