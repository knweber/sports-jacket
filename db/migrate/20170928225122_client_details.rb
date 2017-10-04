class ClientDetails < ActiveRecord::Migration[5.1]
  def up
    create_table :charge_client_details do |t|
      t.string :charge_id
      t.string :browser_ip
      t.string :user_agent
      
    end
    add_index :charge_client_details, :charge_id

  end

  def down
    remove_index :charge_client_details, :charge_id
    drop_table :charge_client_details
    
  end
end
