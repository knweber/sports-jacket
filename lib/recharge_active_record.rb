require_relative 'init'
require 'active_support'
require 'active_support/core_ext'
require_relative 'logging'

module RechargeActiveRecordInclude
  def self.included(base)
    base.extend(ClassMethods)
    base.before_create :recharge_create_async
    base.before_update :recharge_update_async
    base.before_destroy :recharge_delete_async
  end

  def as_recharge
    remapped = self.class.api_map.map do |m|
      local = self[m[:local_key]]
      transform = m[:outbound] || ->(i){ i }
      [m[:remote_key], transform.call(local)]
    end
    remapped.to_h
  end

  def recharge_create
    self.class.recharge_endpoint.create as_recharge
  end

  def recharge_create_async
    self.class.recharge_endpoint.async :create, as_recharge
  end

  def recharge_update
    self.class.recharge_endpoint.update id, recharge_changes
  end

  def recharge_update_async
    self.class.recharge_endpoint.async :update, id, recharge_changes
  end

  def recharge_delete
    self.class.recharge_endpoint.delete id
  end

  def recharge_delete_async
    self.class.recharge_endpoint.async :delete, id
  end

  def recharge_changes
    changes = attributes.select{|k, _| changed.include? k}
    self.class.map_out changes
  end

  module ClassMethods

    def from_recharge(obj)
      #raise "Error: #{name}::from_recharge is not defined."
      new(map_in(obj))
    end

    def map_in(remote_obj)
      remapped = api_map.map do |m|
        remote = remote_obj[m[:remote_key]]
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

    def recharge_endpoint
      Recharge.const_get name
    end

    private

    def diff(left, right)
      column_names.reject { |col| left[col] == right[col] }
    end

  end
end
