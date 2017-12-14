require_relative 'init'
require 'active_support'
require 'active_support/core_ext'
require_relative 'logging'

module ShopifyActiveRecordInclude
  def self.included(base)
    base.extend(ClassMethods)
    base.before_create :shopify_create
    base.before_update :shopify_update
    base.before_destroy :shopify_delete
  end

  def as_shopify
    remapped = self.class.api_map.map do |m|
      local = self[m[:local_key]]
      transform = m[:outbound] || ->(i){ i }
      [m[:remote_key], transform.call(local)]
    end
    remapped.to_h
  end

  def shopify_create
    self.class.shopify_create(as_shopify)
  end

  def shopify_create_async
    self.class.async :shopify_create, as_shopify
  end

  def shopify_update
    self.class.shopify_update(id, as_shopify)
  end

  def shopify_update_async
    self.class.async :shopify_update, id, as_shopify
  end

  def shopify_delete
    self.class.shopify_delete(id)
  end

  def shopify_delete_async
    self.class.async :shopify_delete, id
  end

  module ClassMethods

    def from_shopify(obj)
      #raise "Error: #{name}::from_shopify is not defined."
      new(map_in(obj))
    end

    def map_in(obj)
      remapped = api_map.map do |m|
        remote = obj[m[:remote_key]]
        transform = m[:inbound]
        [m[:local_key], transform.call(remote)]
      end
      remapped.to_h
    end

    def shopify_create(data)
      shopify = ShopifyAPI.const_get name
      shopify.create(data)
    end

    def shopify_update(id, data)
      shopify = ShopifyAPI.const_get name
      shopify.update(id, data)
    end

    def shopify_delete(id)
      shopify = ShopifyAPI.const_get name
      shopify.delete(id)
    end

    private

    def diff(left, right)
      column_names.reject { |col| left[col] == right[col] }
    end

  end
end
