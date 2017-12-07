require 'resque'
require 'shopify_api'
require_relative '../lib/async'
require_relative '../models/config'

ShopifyAPI::Base.site = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin" 

class Rollover
  include Async

  def self.set_current_theme_id
    themes = ShopifyAPI::Theme.all
    id = themes.select{|t| t.role == 'main'}.first.id
    Config[:current_theme_id] = id
  end

  # updates a given subscription id to a new product
  def self.product_id(subscription_id, new_product_id)

  end
end
