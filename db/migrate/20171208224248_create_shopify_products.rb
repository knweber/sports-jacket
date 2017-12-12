class CreateShopifyProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.text :body_html, null: false, default: ''
      t.string :shopify_id, null: false
      t.string :handle
      t.jsonb :images
      t.jsonb :options
      t.string :product_type
      t.timestamp :published_at
      t.json :image
      t.jsonb :images
      t.string :published_scope
      t.string :tags
      t.string :template_suffix
      t.string :title
      t.string :metafields_global_title_tag
      t.string :metafields_global_description_tag
      t.jsonb :variants
      t.string :vendor

      t.timestamps
    end
  end
end
