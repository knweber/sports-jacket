require 'active_record'
require 'active_record/base'
require_relative '../lib/recharge_active_record'
require_relative '../lib/async'
require_relative 'application'

class SkipReason < ActiveRecord::Base
  belongs_to :charge
  belongs_to :subscription
  belongs_to :customer, primary_key: :shopify_customer_id, foreign_key: :shopify_customer_id
end
