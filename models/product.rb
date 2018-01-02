require_relative '../lib/init'
require_relative '../lib/async'
require_relative 'application'

class Product < ActiveRecord::Base
  include ApplicationRecord
  self.primary_key = :shopify_id
end
