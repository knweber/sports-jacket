require_relative '../lib/init'
require_relative '../models/all'
require_relative '../lib/async'

# used to fetch shopify api caching tables
class ShopifyPull
  include Async

  def self.all_products(options = {})
    options[:limit] ||= 250
    count = ShopifyAPI::Product.count
    pages = count.fdiv(options[:limit]).ceil
    (1..pages).each do |page|
      async(:products, page: page, limit: options[:limit])
    end
  end

  def self.products(options = {})
    products = ShopifyAPI::Product.where(options)
    Product.transaction do
      products.each do |product|
        local_product = Product.find_or_initialize_by(shopify_id: product.id)
        local_product.attributes = product.attributes.reject{|k,_| k == 'id'}
        local_product.save!(validate: false)
      end
    end
  end
end
