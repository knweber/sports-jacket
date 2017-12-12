require 'sinatra/base'
# module designed to generate crud routes for active record models
module Sinatra
  module CrudRoutes

    def crud(model)
      get('/') {|_| Routes.index_route(model) }
      get('/:id') {|id| Routes.read_route(model, id) }
      post('/') {|_| Routes.create_route(model) }
      put('/:id') {|id| Routes.update_route(model, id) }
      patch('/:id') {|id| Routes.update_route(model, id) }
      delete('/:id') {|id| Routes.delete_route(model, id) }
    end

    module Routes
      def index_route(model, options = {})
        raise 'unimplemented'
      end

      def read_route(model, id)
        raise 'unimplemented'
      end

      def create_route(model, id)
        raise 'unimplemented'
      end

      def update_route(model, id)
        raise 'unimplemented'
      end

      def delete_route(model, id)
        raise 'unimplemented'
      end
    end

  end
  register CrudRoutes
end
