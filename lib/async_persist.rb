require_relative 'init'
require_relative 'async'

# used for active record callbacks to asyncronously update shopify models
class PersistShopify
  include Async

  def create(model, data)
  end

  def update(model, id, data, changes = nil)
  end

  def delete(model, id)
  end
end

module PersistRecharge
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
  end
end
