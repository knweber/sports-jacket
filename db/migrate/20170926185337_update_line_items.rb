class UpdateLineItems < ActiveRecord::Migration[5.1]
  def up
    create_table :update_line_items do |t|
      t.string :subscription_id
      t.string :properties
      t.boolean :updated, default: false
      

    end
  end

  def down
    drop_table :update_line_items
  end
end
