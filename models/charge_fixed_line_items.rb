require 'active_record'
require 'active_record/base'
require_relative '../lib/recharge_api'
require_relative '../lib/async'

class ChargeFixedLineItems < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :charge
end

