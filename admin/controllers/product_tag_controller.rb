require 'grape'
require 'grape-entity'
require_relative '../../models/product_tag.rb'

module ProductTagController 
  class API < Grape::API

    #expose :product_id, :tag, :active_start, :active_end, :theme_id

    get '/product_tags' do
      ProductTag.all.as_json
    end

    desc 'Create a new product tag'
    post '/product_tags' do
      ProductTag.create! params
    end
  end
  class Entity < Grape::Entity
  end
end


