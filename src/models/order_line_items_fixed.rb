require 'active_record'
require 'active_record/base'
require_relative '../recharge_api'
require_relative '../async'
require_relative 'application'

class OrderLineItemsFixed < ActiveRecord::Base
  include ApplicationRecord
  self.table_name = 'order_line_items_fixed'
  belongs_to :subscription
  belongs_to :order
end
