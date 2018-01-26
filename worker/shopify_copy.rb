require_relative '../config/environment'
require_relative '../lib/async'

# WIP
class ShopifyCopy
  include Async

  ENTITIES = [
    'Article',
    'Asset',
    'Blog',
    'Comment',
    'CarrierService',
    'Checkout',
    'Collection',
    'Collect',
    'CollectionListing',
    'Country',
    'Province',
    'CustomCollection',
    'Customer',
    'CustomerAddress',
    'CustomerSaveSearch',
    'DiscountCode',
    'DraftOrder',
    'Event',
    'GiftCard',
    'Location',
    'MarketingEvent',
    'MetaField',
    'Multipass',
    'Order',
    'OrderRisks',
    'Page',
    'Policy',
    'PriceRule',
    'Product',
    'ProductImage',
    'ProductVariant',
    'ProductListing',
    'Province',
    'RecurringApplicationCharge', # not applicable to ellie
    'Redirect',
    'Refund',
    'Report',
    'ResourceFeedback',
    'ScriptTag',
    'ShippingZone',
    'Shop',
    'SmartCollection',
    'StorefrontAccessToken',
    'Theme',
    'Transaction',
    'UsageCharge', # not applicable to ellie
    #'User', # not writeable
    'Webhook',
    'ShopifyQL',
  ].freeze

  def self.constantize(string)
    ShopifyAPI.const_get(string)
  end

  # construct a shopify admin url with credentials
  def self.url(shop_name, api_key, password)
    "https://#{api_key}:#{password}@#{shop_name}.myshopify.com/admin"
  end

  # Copy a complete shop from one store to another. URLs must include admin
  # authentication credentials
  def self.copy_all(source_url, target_url)
  end

  def self.copy_all_entity(source_url, target_url, entity, where = {})
    ShopifyAPI::Base.site = source_url
    where[:limit] ||= 250
    klass = constantize entity
    count = klass.where(where).try :count
    pages = count.fdiv(where[:limit]).ceil
    (1..pages).each do |page|
      ShopifyAPI::Base.site = source_url
      source_data = klass.where({page: page}.merge(where))
      ShopifyAPI::Base.site = target_url
      source_data.each do |obj|
        klass.async :create, obj.attributes
      end
    end
  end

  def self.delete_all(target_url, entity, where = {})
    ShopifyAPI::Base.site = target_url
    klass = constantize entity
    where[:limit] ||= 250
    count = klass.where(where).count
    pages = count.fdiv(count).ceil
    (1..pages).each do |page|
      ids = klass.where({page: page}.merge(where)).map(&:id)
      ids.each{|id| klass.async :delete, id}
    end
  end

end
