require_relative 'init'
require 'active_support'
require 'active_support/core_ext'
require_relative 'logging'

module ShopifyActiveRecordInclude
  def self.included(base)
    base.extend(ClassMethods)

    base.before_create :shopify_create_async
    base.before_update :shopify_update_async
    base.before_destroy :shopify_delete_async
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
    self.class.shopify_class.create(as_shopify)
  end

  def shopify_create_async
    self.class.shopify_class.async :create, as_shopify
  end

  def shopify_update
    data = self.class.map_out active_changes
    self.class.shopify_class.update(id, data)
  end

  def shopify_update_async
    data = self.class.map_out active_changes
    self.class.shopify_class.async :update, id, data
  end

  def shopify_delete
    self.class.shopify_class.delete(id)
  end

  def shopify_delete_async
    self.class.shopify_class.async :delete, id
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

    def map_out(local_obj)
      remapped = local_obj.map do |key, val|
        map = api_map.find{|m| m[:local_key] == key}
        next [key, val] if map.nil?
        [map[:remote_key], map[:outbound].call(val)]
      end
      remapped.to_h
    end

    def shopify_class
      ShopifyAPI.const_get name
    end

    private

    def diff(left, right)
      column_names.reject { |col| left[col] == right[col] }
    end

  end
end
