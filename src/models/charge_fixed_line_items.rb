require 'active_record'
require 'active_record/base'
require_relative '../recharge_api'
require_relative '../async'

class ChargeFixedLineItems < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :charge
end

