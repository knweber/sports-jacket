class SubLineItems < ActiveRecord::Migration[5.1]
  def up
    create_table :sub_line_items do |t|
      t.string :subscription_id
      t.string :name
      t.string :value
      

    end
  end

  def down
    drop_table :sub_line_items
  end
end
