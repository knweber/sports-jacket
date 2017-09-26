#FAMBrands download subscription
#get_ellie_info.rb

require 'httparty'
require 'dotenv'
require 'pg'
require 'sinatra/activerecord'
require 'active_support/core_ext'



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
        end

        def count_subscriptions
            uri = URI.parse(ENV['DATABASE_URL'])
            conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)

            my_insert = "insert into subscriptions (subscription_id, address_id, customer_id, created_at, updated_at, next_charge_scheduled_at, cancelled_at, product_title, price, quantity, status, shopify_product_id, shopify_variant_id, sku, order_interval_unit, order_interval_frequency, charge_interval_frequency, order_day_of_month, order_day_of_week, raw_line_item_properties) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)"
            conn.prepare('statement1', "#{my_insert}")
            my_line_item_insert = "insert into sub_line_items (subscription_id, name, value) values ($1, $2, $3)"
            conn.prepare('statement2', "#{my_line_item_insert}")

            response = HTTParty.get("https://api.rechargeapps.com/subscriptions/count", :headers => @my_header)
            #puts response.inspect
            my_response = JSON.parse(response)
            #puts my_response.inspect
            my_count = my_response['count'].to_i
            puts "We have #{my_count} subscriptions"
            #puts "hello"
            my_temp_array = Array.new

            page_size = 250
            num_pages = (my_count/page_size.to_f).ceil
            1.upto(num_pages) do |page|
                mysubs = HTTParty.get("https://api.rechargeapps.com/subscriptions?limit=250&page=#{page}", :headers => @my_header)
                #puts mysubs.inspect
                local_sub = mysubs['subscriptions']
                local_sub.each do |sub|
                    if !sub['properties'].nil? && sub['properties'] != []
                    puts "**************"
                    puts sub.inspect
                    id = sub['id']
                    address_id = sub['address_id']
                    customer_id = sub['customer_id']
                    created_at = sub['created_at']
                    updated_at = sub['updated_at']
                    #handle nils for these
                    next_charge_scheduled_at = sub['next_charge_scheduled_at']
                    cancelled_at = sub['cancelled_at']
                    

                    product_title = sub['product_title']
                    variant_title = sub['variant_title']
                    price = sub['price']
                    quantity = sub['quantity']
                    shopify_product_id = sub['shopify_product_id']
                    shopify_variant_id = sub['shopify_variant_id']
                    sku = sub['sku']
                    status = sub['status']
                    order_interval_unit = sub['order_interval_unit']
                    order_interval_frequency  = sub['order_interval_frequency']
                    charge_interval_frequency = sub['charge_interval_frequency']
                    cancellation_reason = sub['cancellation_reason']
                    
                    order_day_of_week = sub['order_day_of_week']
                    
                    order_day_of_month = sub['order_day_of_month']
                    
                    properties  = sub['properties'].to_json
                    conn.exec_prepared('statement1', [id, address_id, customer_id, created_at, updated_at, next_charge_scheduled_at, cancelled_at, product_title, price, quantity, status, shopify_product_id, shopify_variant_id, sku, order_interval_unit, order_interval_frequency, charge_interval_frequency, order_day_of_month, order_day_of_week, properties ])


                    puts sub['properties'].inspect
                    my_temp_array = sub['properties']
                    my_temp_array.each do |temp|
                        #puts temp.inspect
                        temp_name = temp['name']
                        temp_value = temp['value']
                        puts "#{temp_name}, #{temp_value}"
                        conn.exec_prepared('statement2', [id, temp_name, temp_value])
                    end
                    puts "**************"
                    end
                end 
                puts "Done with page #{page}"
                puts "Sleeping #{@sleep_recharge}"
                sleep @sleep_recharge.to_i
            end        
            conn.close


        end

        def update_line_item_properties
            uri = URI.parse(ENV['DATABASE_URL'])
            conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
            my_query = "select subscription_id from subscriptions"
            
            my_properties_insert = "insert into update_line_items (subscription_id, properties) values ($1, $2)"
            conn.prepare('statement1', "#{my_properties_insert}")
            result_set = conn.exec(my_query)
            result_set.each do |row|
                sports_jacket_present = false
                temp_jacket_size = ""
                temp_property_array = Array.new
                sub_id = row['subscription_id']
                puts sub_id
                my_properties = "select name, value from sub_line_items where subscription_id = \'#{sub_id}\'"
                properties_result = conn.exec(my_properties)
                properties_result.each do |myrow|
                    myname = myrow['name']
                    myvalue = myrow['value']
                    temp_jacket_size = ""
                    puts "#{myname}, #{myvalue}"
                    local_json_string = {"name" => myname, "value" => myvalue}
                    temp_property_array << local_json_string
                    if myname == "sports-jacket"
                        sports_jacket_present = true
                    end
                    if myname == "tops"
                        temp_jacket_size = myvalue
                    end

                    
                    

                end
                if !sports_jacket_present && temp_jacket_size != ""
                    temp_jacket_properties = {"name" => "sports-jacket", "value" => temp_jacket_size}
                    temp_property_array << temp_jacket_properties
                    puts "------------"
                    json_data = {"properties" => temp_property_array}.to_json
                    puts json_data.inspect
                    #insert temp_property_array into update table
                    conn.exec_prepared('statement1', [sub_id, json_data])
                
                end
                
            end
            conn.close
        end

        def delete_tables
            uri = URI.parse(ENV['DATABASE_URL'])
            conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
          
            my_subscription_delete = "delete from subscriptions"
            my_sub_line_items_delete = "delete from sub_line_items"
            my_update_line_items = "delete from update_line_items"
            conn.exec(my_subscription_delete)
            conn.exec(my_sub_line_items_delete)
            conn.exec(my_update_line_items)
            puts "all done deleting subscriptions, sub_line_items, and update_line_items tables"
        end

        def testing_update_justin
            #GET /subscriptions?shopify_customer_id=12345

            #justin shopify_id = 5021489349
            my_shopify_id = "5021489349"
            response = HTTParty.get("https://api.rechargeapps.com/subscriptions?shopify_id=#{my_shopify_id}", :headers => @my_header)
            #puts response.parsed_response.inspect
            subs = response.parsed_response
            subs['subscriptions'].each do |local_sub|
                puts "-----------------"
                puts local_sub.inspect
                puts "-----------------"

            end


        end


        def test_update_justin_sub
            
            #test subscription_id to change properties
            local_subscription_id = "5362230"
            uri = URI.parse(ENV['DATABASE_URL'])
            conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
            my_query = "select * from update_line_items where subscription_id = \'#{local_subscription_id}\'"
            result = conn.exec(my_query)
            result.each do |row|
                local_properties = row['properties']
                puts local_properties
                
                property_change_recharge = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{local_subscription_id}", :headers => @my_change_charge_header, :body => local_properties)
                puts property_change_recharge.inspect
            end
            puts "all done with test updade for justin subscription #{local_subscription_id}"
        end

        def update_subscription_sports_jacket
            uri = URI.parse(ENV['DATABASE_URL'])
            conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
            my_query = "select * from update_line_items where updated = \'f\'"
            result = conn.exec(my_query)
            start_time = Time.now
            result.each do |row|
                subscription_id = row['subscription_id']
                properties = row['properties']
                puts "#{subscription_id}, #{properties}"
                begin
                    property_change_recharge = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{subscription_id}", :headers => @my_change_charge_header, :body => properties)  

                rescue => exception
                    puts "We can't process id #{subscription_id}"
                else
                    #mark processed to true
                    my_update = "update update_line_items set updated = \'t\'  where subscription_id = \'#{subscription_id}\'"
                    conn.exec(my_update)    
                ensure
                   puts "Done with this record" 
                end
                end_time = Time.now
                duration = (end_time - start_time).ceil
                puts "running #{duration} seconds"
                if duration > 480
                    puts "We have been running #{duration} seconds, must exit"
                    exit
                end
            end

        end

        def sub_testing
            uri = URI.parse(ENV['DATABASE_URL'])
            conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
            my_query = "select subscription_id as sub_id, raw_line_item_properties from subscriptions"
            result = conn.exec(my_query)
            result.each do |row|
                line_item = eval(row['raw_line_item_properties'])
                line_item.each do |myitem|
                    temp_item = myitem.to_h
                    if temp_item.has_value?("tops")
                    puts temp_item
                    end

                end

            end

        end


        def retrieve_sub
            #7508212
            #7507789
            my_sub_id = 7508212
            #GET /subscriptions/<subscription_id>
            response = HTTParty.get("https://api.rechargeapps.com/subscriptions/#{my_sub_id}", :headers => @my_header)
            subs = response.parsed_response
            puts subs.inspect



        end


    end
end
