require 'resque'

# This module is designed to be included in active record / recharge models. It
# procides the #async_save method that creates a resque task to persist to
# recharge and the caching database. Assumes the presence of an #as_recharge and
# #recharge_endpoint method that transforms the data into a hash that matches
# the recharge api.
module Async
  def included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods
    def perform(method, obj, options)
      send(method, obj)
    end

    def async(method, obj, options)
      Resque.enqueue(self, method, obj, options)
    end

    def key_name
      "#{name.downcase}_id"
    end
  end
end
