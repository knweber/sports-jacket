require 'active_record/base'
require_relative 'application'

class ChargeShippingLine < ActiveRecord::Base
  include ApplicationRecord
  self.table_name = 'charges_shipping_lines'
  belongs_to :charge
end
