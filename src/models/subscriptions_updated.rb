require 'active_record'
require 'active_record/base'
require_relative '../recharge_api'
require_relative '../async'

class SubscriptionsUpdated < ActiveRecord::Base
  self.table_name = "subscriptions_updated"
end
