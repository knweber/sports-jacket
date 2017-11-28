class RenameHash < ActiveRecord::Migration[5.1]
  def up
    #rename_column :customers, :hash, :customer_hash
  end

  def down
    #rename_column :customers, :customer_hash, :hash
  end
end
