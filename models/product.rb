class Product < ActiveRecord::Base
  include ApplicationRecord
  self.primary_key = :shopify_id
end
