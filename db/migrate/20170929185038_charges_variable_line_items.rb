class ChargesVariableLineItems < ActiveRecord::Migration[5.1]
  def up
    create_table :charge_variable_line_items do |t|
      t.string :charge_id
      t.string :name
      t.string :value
      

      
    end
    add_index :charge_variable_line_items, :charge_id

  end

  def down
    remove_index :charge_fixed_line_items, :charge_id 
    drop_table :charge_variable_line_items
    
  end
end
