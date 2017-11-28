class RenameType < ActiveRecord::Migration[5.1]
  def up
    #rename_column :orders, :type, :order_type
  end

  def down
    #rename_column :orders, :order_type, :type
  end


end
