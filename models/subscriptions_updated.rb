require 'active_record'
require 'active_record/base'
require_relative '../lib/recharge_active_record'
require_relative '../lib/async'

class SubscriptionsUpdated < ActiveRecord::Base
  self.table_name = "subscriptions_updated"
end
