require_relative '../lib/async'
require_relative '../lib/init'
require_relative '../models/config'


class Rollover
  include Async

  def self.set_current_theme_id
    themes = ShopifyAPI::Theme.all
    id = themes.select{|t| t.role == 'main'}.first.id
    Config[:current_theme_id] = id
  end

  # updates subscription products
  # map: Hash keyed by the product ids to be changed with values of a hash of
  # the values to be updated. For example:
  #
  # map = {
  #   123456789: {
  #     shopify_product_id: 234567891,
  #     shopify_variant_id: 491728340,
  #   },
  # }
  def self.subscription_products(map)
    Subscription.where(shopify_product_id: map.keys).each do |sub|
      data = map[sub.shopify_product_id]
      data[:id] = sub.id
      Recharge::Subscription.async :update, sub.id, data
    end
  end
end
