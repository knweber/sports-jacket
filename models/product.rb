require 'active_record'
require 'active_record/base'
require_relative '../lib/async'
require_relative 'application'
require 'shopify_api'

class Product < ActiveRecord::Base
  include ApplicationRecord
end
