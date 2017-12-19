require_relative '../lib/init'
require 'active_record/base'
require_relative '../lib/async'
require_relative 'application'
require 'shopify_api'

class Product < ActiveRecord::Base
  include ApplicationRecord
  self.primary_key = :shopify_id
end
