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

        def update_three_months_subs
            my_delete = "delete from subscription_update"
            my_alter = "alter sequence subscription_update_id_seq RESTART with 1"
            my_insert = "insert into subscription_update (subscription_id, customer_id, first_name, last_name, product_title, shopify_product_id, shopify_variant_id, sku)  select subscriptions.subscription_id, customers.customer_id, customers.first_name, customers.last_name, subscriptions.product_title, subscriptions.shopify_product_id, subscriptions.shopify_variant_id, subscriptions.sku from customers, subscriptions where customers.customer_id = subscriptions.customer_id and subscriptions.product_title = \'3 MONTHS\' and subscriptions.status = \'ACTIVE\'"
            @conn.exec(my_delete)
            puts "Deleted stuff in subscription_update table"
            @conn.exec(my_alter)
            puts "Renumbering id sequence back to 1"
            @conn.exec(my_insert)
            puts "inserted three month subscriptions into update table for processing"

        end

        def process_three_month_subs
            my_start = Time.now
            my_prod_title = "3 MONTHS"
            my_shopify_prod_id = "23729012754"
            my_shopify_variant_id = "177939546130"
            my_sku = "722457572908"
            body = {"product_title" => my_prod_title, "shopify_product_id" => my_shopify_prod_id, "shopify_variant_id" => my_shopify_variant_id, "sku" => my_sku}.to_json
            my_temp_update = "update subscription_update set updated = $1, updated_at = $2  where subscription_id = $3"
            @conn.prepare('statement2', "#{my_temp_update}")
            my_select = "select * from subscription_update where updated = \'f\'"
            result = @conn.exec(my_select)
            result.each do |row|
                my_sub_id = row['subscription_id']
                my_last_name = row['last_name']
                my_first_name = row['first_name']
                puts "#{my_sub_id}, #{my_first_name}, #{my_last_name}"
                #7780091, Justin, Zarabi
                
                my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{my_sub_id}", :headers => @my_change_charge_header, :body => body, :timeout => 80)
                puts my_update_sub.inspect
                sleep 6
                update_success = false
                if my_update_sub.code == 200
                  update_success = true
                  puts "****** Hooray We have no errors **********"
                end
                if update_success
                    my_now = DateTime.now
                    my_now_str = my_now.strftime("%Y-%m-%d %H:%M:%S")
                    puts my_now_str
                    indy_result = @conn.exec_prepared('statement2', [true, my_now_str, my_sub_id])
                    puts indy_result.inspect

                else
                    puts "Cound not update subscription #{my_sub_id}, for #{my_first_name} #{my_last_name}"
                end
                my_current = Time.now
                my_duration = (my_current - my_start).ceil
                puts "duration = #{my_duration}"
                if my_duration > 480
                    puts "Duration more than 480 seconds, 8 minutes"
                    puts "Exiting now"
                    exit

                end

            end



        end


    end
end
