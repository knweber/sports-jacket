# This module is designed to be included in active record / recharge models. It
# procides the #async_save method that creates a resque task to persist to
# recharge and the caching database. Assumes the presence of an #as_recharge and
# #recharge_endpoint method that transforms the data into a hash that matches
# the recharge api.
module Async
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def queue
      :default
    end

    def perform(method, *args)
      send(method, *args)
    end

    def async(method, *args)
      Resque.enqueue(self, method, *args)
    end
  end
end
