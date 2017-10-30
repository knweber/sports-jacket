#FAMBrands download subscription
#get_ellie_info.rb

require 'httparty'
require 'dotenv'
require 'pg'
require 'sinatra/activerecord'
require 'active_support/core_ext'
require 'resque'
require_relative 'worker_helper'



module DetermineInfo
    class InfoGetter

        def initialize
            Dotenv.load
            recharge_regular = ENV['RECHARGE_ACCESS_TOKEN']
            @sleep_recharge = ENV['RECHARGE_SLEEP_TIME']
            @my_header = {
                "X-Recharge-Access-Token" => recharge_regular
            }
            @my_change_charge_header = {
                "X-Recharge-Access-Token" => recharge_regular,
                "Accept" => "application/json",
                "Content-Type" =>"application/json"
            }
            @uri = URI.parse(ENV['DATABASE_URL'])
            @conn = PG.connect(@uri.hostname, @uri.port, nil, nil, @uri.path[1..-1], @uri.user, @uri.password)
        end

        

        

        


        

        

        


        

        

        

        

        def handle_customers(option)
            params = {"option_value" => option, "connection" => @uri, "header_info" => @my_header, "sleep_recharge" => @sleep_recharge}
            if option == "full_pull"
                puts "Doing full pull of customers"
                #delete tables and do full pull
                puts @uri.inspect
                
                Resque.enqueue(PullCustomer, params)

            elsif option == "yesterday"
                puts "Doing partial pull of customers since yesterday"
                #params = {"option_value" => option, "connection" => @uri}
                Resque.enqueue(PullCustomer, params)
            else
                puts "sorry, cannot understand option #{option}, doing nothing."
            end

        end


        class PullCustomer
            extend EllieHelper
            @queue = "pull_customer"
            def self.perform(params)
                puts params.inspect
                get_customers_full(params)

            end

        end

        def handle_charges(option)
            params = {"option_value" => option, "connection" => @uri, "header_info" => @my_header, "sleep_recharge" => @sleep_recharge}
            if option == "full_pull"
                puts "Doing full pull of charge table and associated charge tables"
                #delete tables and do full pull
                #puts @uri.inspect
                
                Resque.enqueue(PullCharge, params)

            elsif option == "yesterday"
                puts "Doing partial pull of charge table and associated tables since yesterday"
                #params = {"option_value" => option, "connection" => @uri}
                Resque.enqueue(PullCharge, params)
            else
                puts "sorry, cannot understand option #{option}, doing nothing."
            end

        end


        class PullCharge
            extend EllieHelper
            @queue = "pull_charge"
            def self.perform(params)
                puts params.inspect
                get_charge_full(params)

            end
        end

        def handle_orders(option)
            params = {"option_value" => option, "connection" => @uri, "header_info" => @my_header, "sleep_recharge" => @sleep_recharge}
            if option == "full_pull"
                puts "Doing full pull of orders table and associated order tables"
                #delete tables and do full pull
                #puts @uri.inspect
                
                Resque.enqueue(PullOrder, params)

            elsif option == "yesterday"
                puts "Doing partial pull of orders table and associated tables since yesterday"
                Resque.enqueue(PullOrder, params)
            else
                puts "sorry, cannot understand option #{option}, doing nothing."
            end

        end

        class PullOrder
            extend EllieHelper
            @queue = "pull_order"
            def self.perform(params)
                puts params.inspect
                get_order_full(params)
            end
        end


        def handle_subscriptions(option)
            params = {"option_value" => option, "connection" => @uri, "header_info" => @my_header, "sleep_recharge" => @sleep_recharge}
            if option == "full_pull"
                puts "Doing full pull of subscription table and associated tables"
                #delete tables and do full pull
                #puts @uri.inspect
                
                Resque.enqueue(PullSubscription, params)

            elsif option == "yesterday"
                puts "Doing partial pull of subscription table and associated tables since yesterday"
                Resque.enqueue(PullSubscription, params)
            else
                puts "sorry, cannot understand option #{option}, doing nothing."
            end

        end

        class PullSubscription
            extend EllieHelper
            @queue = "pull_subscriptions"
            def self.perform(params)
                puts params.inspect
                get_sub_full(params)
            end

        end


    end
end
