class AddMissingChargeColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :charges, :raw_line_items, :jsonb, default: [], null: false
    add_column :charges, :raw_shipping_lines, :jsonb, default: [], null: false
    add_column :charges, :browser_ip, :string
  end
end
