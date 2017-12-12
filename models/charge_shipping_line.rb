require 'active_record'
require 'active_record/base'
require_relative '../lib/recharge_api'
require_relative '../lib/async'
require_relative 'application'

class ChargeShippingLine < ActiveRecord::Base
  include ApplicationRecord
  self.table_name = 'charges_shipping_lines'
  belongs_to :charge
end