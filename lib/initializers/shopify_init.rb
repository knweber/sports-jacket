require_relative '../async'
ShopifyAPI::Base.site = "https://#{ENV['WORKER_SHOPIFY_API_KEY']}:#{ENV['WORKER_SHOPIFY_PASSWORD']}@#{ENV['WORKER_SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
ShopifyAPI::Base.include Async
