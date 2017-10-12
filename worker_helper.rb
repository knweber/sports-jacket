#file worker_helper.rb

module EllieHelper

    def get_customers_full(params)
        puts "here params are #{params}"
        option_value = params['option_value']
        uri = params['connection']
        sleep_recharge = params['sleep_recharge']
        puts sleep_recharge
        puts uri
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        #puts my_conn.inspect
        header_info = params['header_info']
        puts header_info

        #check full pull or partial since yesterday

        if option_value == "full_pull"
            #delete all customer_tables
            puts "Deleting customer table"
            customers_delete = "delete from customers"
            customers_reset = "ALTER SEQUENCE customers_id_seq RESTART WITH 1"
            my_conn.exec(customers_delete)
            my_conn.exec(customers_reset)
            puts "Deleted all customer table information and reset the id sequence"
            my_conn.close
            num_customers = background_count_customers(header_info)
            puts "We have #{num_customers} to download"
            background_load_full_customers(sleep_recharge, num_customers, header_info, uri)
            


        elsif option_value == "yesterday"
            puts "downloading only yesterday's customers"
            my_today = Date.today
            puts "Today is #{my_today}"
            my_yesterday = my_today - 1
            #puts "Yesterday was #{my_yesterday}, header_info = #{header_info}"
            num_updated_cust = background_count_yesterday_customers(my_yesterday, header_info)
            puts "We have #{num_updated_cust} customers who are new or have been updated since yesterday"
            background_load_modified_customers(sleep_recharge, num_updated_cust, header_info, uri)

        else
            puts "Sorry can't understand what the option_value #{option_value} means"

        end
    end

    def background_count_customers(my_header)
        #GET /customers/count
        customer_count = HTTParty.get("https://api.rechargeapps.com/customers/count", :headers => my_header)
        my_count = customer_count.parsed_response
        puts my_count.inspect
        num_customers = my_count['count']
        puts num_customers
        num_customers = num_customers.to_i
        puts num_customers
        return num_customers
    end

    def background_load_full_customers(sleep_recharge, num_customers, my_header, uri)
        puts "starting download"
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_insert = "insert into customers (customer_id, hash, shopify_customer_id, email, created_at, updated_at, first_name, last_name, billing_address1, billing_address2, billing_zip, billing_city, billing_company, billing_province, billing_country, billing_phone, processor_type, status) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)"
        my_conn.prepare('statement1', "#{my_insert}") 

        start = Time.now
        page_size = 250
        num_pages = (num_customers/page_size.to_f).ceil
        1.upto(num_pages) do |page|
            customers = HTTParty.get("https://api.rechargeapps.com/customers?limit=250&page=#{page}", :headers => my_header)
            my_customers = customers.parsed_response['customers']
            puts "----------------------------------"
            #puts my_customers.inspect
            my_customers.each do |mycust|
                puts "******************"
                puts mycust.inspect
                puts "******************"
                customer_id = mycust['id']
                hash = mycust['hash']
                shopify_customer_id = mycust['shopify_customer_id']
                email = mycust['email']
                created_at = mycust['created_at']
                updated_at = mycust['updated_at']
                first_name = mycust['first_name']
                last_name = mycust['last_name']
                billing_address1 = mycust['billing_address1']
                billing_address2 = mycust['billing_address2']
                billing_zip = mycust['billing_zip']
                billing_city = mycust['billing_city']
                billing_company = mycust['billing_company']
                billing_province = mycust['billing_province']
                billing_country = mycust['billing_country']
                billing_phone = mycust['billing_phone']
                processor_type = mycust['processor_type']
                status = mycust['status']
                my_conn.exec_prepared('statement1', [customer_id, hash, shopify_customer_id, email, created_at, updated_at, first_name, last_name, billing_address1, billing_address2, billing_zip, billing_city, billing_company, billing_province, billing_country, billing_phone, processor_type, status])

            end
            puts "----------------------------------"
            puts "Done with page #{page}"
            current = Time.now
            duration = (current - start).ceil
            puts "Running #{duration} seconds"
            puts "Sleeping #{sleep_recharge}"
            sleep sleep_recharge.to_i 
        end
        puts "All done"
        my_conn.close
    end

    def background_count_yesterday_customers(my_yesterday, my_header)
        #puts "starting partial download"
        #puts my_yesterday
        #puts "my_header = #{my_header}"
        updated_at_min = my_yesterday.strftime("%Y-%m-%d")
       # puts updated_at_min
        customer_count = HTTParty.get("https://api.rechargeapps.com/customers/count?updated_at_min=#{updated_at_min}", :headers => my_header)
        my_count = customer_count.parsed_response
        puts my_count
        num_customers = my_count['count']
        num_customers = num_customers.to_i
        return num_customers
    end


    def background_load_modified_customers(sleep_recharge, num_customers, my_header, uri)
        puts "Doing partial download new or modified customers since yesterday"
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_insert = "insert into customers (customer_id, hash, shopify_customer_id, email, created_at, updated_at, first_name, last_name, billing_address1, billing_address2, billing_zip, billing_city, billing_company, billing_province, billing_country, billing_phone, processor_type, status) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)"
        my_conn.prepare('statement1', "#{my_insert}") 

        #Delete all customers from day before yesterday
        my_temp_update = "update customers set hash = $1, email = $2,  updated_at = $3, first_name = $4, last_name = $5, billing_address1 = $6, billing_address2 = $7, billing_zip = $8, billing_city = $9, billing_company = $10, billing_province = $11, billing_country = $12, billing_phone = $13, processor_type = $14, status = $15  where customer_id = $16 "
        my_conn.prepare('statement2', "#{my_temp_update}")


        start = Time.now
        page_size = 250
        num_pages = (num_customers/page_size.to_f).ceil
        1.upto(num_pages) do |page|
            customers = HTTParty.get("https://api.rechargeapps.com/customers?limit=250&page=#{page}", :headers => my_header)
            my_customers = customers.parsed_response['customers']
            puts "----------------------------------"
            #puts my_customers.inspect
            my_customers.each do |mycust|
                puts "******************"
                puts mycust.inspect
                puts "******************"
                customer_id = mycust['id']
                hash = mycust['hash']
                shopify_customer_id = mycust['shopify_customer_id']
                email = mycust['email']
                created_at = mycust['created_at']
                updated_at = mycust['updated_at']
                first_name = mycust['first_name']
                last_name = mycust['last_name']
                billing_address1 = mycust['billing_address1']
                billing_address2 = mycust['billing_address2']
                billing_zip = mycust['billing_zip']
                billing_city = mycust['billing_city']
                billing_company = mycust['billing_company']
                billing_province = mycust['billing_province']
                billing_country = mycust['billing_country']
                billing_phone = mycust['billing_phone']
                processor_type = mycust['processor_type']
                status = mycust['status']
                my_ind_select = "select * from customers where customer_id = \'#{customer_id}\'"
                temp_result = my_conn.exec(my_ind_select)
                if !temp_result.num_tuples.zero?
                    puts "&&&&&&&&&&&&&&&&&"
                    puts "Found existing record"
                    temp_result.each do |myrow|
                        customer_id = myrow['customer_id']
                        puts "Customer ID #{customer_id}"
                        indy_result = my_conn.exec_prepared('statement2', [hash, email,  updated_at, first_name, last_name, billing_address1, billing_address2, billing_zip, billing_city, billing_company, billing_province, billing_country, billing_phone, processor_type, status, customer_id])
                        puts indy_result.inspect
                    end
                    puts "&&&&&&&&&&&&&&&&&&&"
                else
                    puts "Need to insert a new record"
                    puts "+++++++++++++++++++++++++++++++"
                    puts "inserting #{customer_id}, #{first_name} #{last_name}"
                    ins_result = my_conn.exec_prepared('statement1', [customer_id, hash, shopify_customer_id, email, created_at, updated_at, first_name, last_name, billing_address1, billing_address2, billing_zip, billing_city, billing_company, billing_province, billing_country, billing_phone, processor_type, status])
                    puts ins_result.inspect
                    puts "++++++++++++++++++++++++++++++"
                    #sleep 4
                end
                
            end
            puts "----------------------------------"
            puts "Done with page #{page}"
            current = Time.now
            duration = (current - start).ceil
            puts "Running #{duration} seconds"
            puts "Sleeping #{sleep_recharge}"
            sleep sleep_recharge.to_i 
        end
        puts "All done"
        my_conn.close

    end




    def get_charge_full(params)
        puts "here params are #{params}"
        option_value = params['option_value']
        uri = params['connection']
        sleep_recharge = params['sleep_recharge']
        puts sleep_recharge
        puts uri
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        #puts my_conn.inspect
        header_info = params['header_info']
        puts header_info

        if option_value == "full_pull"
            #delete all customer_tables
            puts "Deleting charge and associated tables"
            charges_delete = "delete from charges"
            charges_reset = "ALTER SEQUENCE charges_id_seq RESTART WITH 1"
            my_conn.exec(charges_delete)
            my_conn.exec(charges_reset)
            charges_shipping_delete = "delete from charges_shipping_address"
            charges_shipping_reset = "ALTER SEQUENCE charges_shipping_address_id_seq RESTART WITH 1"
            my_conn.exec(charges_shipping_delete)
            my_conn.exec(charges_shipping_reset)
            charges_billing_delete = "delete from charge_billing_address"
            charges_billing_reset = "ALTER SEQUENCE charge_billing_address_id_seq RESTART WITH 1"
            my_conn.exec(charges_billing_delete)
            my_conn.exec(charges_billing_reset)
            charges_client_delete = "delete from charge_client_details"
            charges_client_reset = "ALTER SEQUENCE charge_client_details_id_seq RESTART WITH 1"
            my_conn.exec(charges_client_delete)
            my_conn.exec(charges_client_reset)
            charges_fixed_delete = "delete from charge_fixed_line_items"
            charges_fixed_reset = "ALTER SEQUENCE charge_fixed_line_items_id_seq RESTART WITH 1"
            my_conn.exec(charges_fixed_delete)
            my_conn.exec(charges_fixed_reset)
            charges_variable_delete = "delete from charge_variable_line_items"
            charges_variable_reset = "ALTER SEQUENCE charge_variable_line_items_id_seq RESTART WITH 1"
            my_conn.exec(charges_variable_delete)
            my_conn.exec(charges_variable_reset)
            charges_shipping_lines_delete = "delete from charges_shipping_lines"
            charges_shipping_lines_reset = "ALTER SEQUENCE charges_shipping_lines_id_seq RESTART WITH 1"
        
            puts "Deleted all charge and associated table information and reset the id sequence"
            my_conn.close
            num_charges = background_count_full_charges(header_info)
            puts "We have #{num_charges} to download"
            #background_load_full_customers(sleep_recharge, num_customers, header_info, uri)
            background_load_full_charges(sleep_recharge, num_charges, header_info, uri)


        elsif option_value == "yesterday"
            puts "downloading only yesterday's charges and associated tables"
            my_today = Date.today
            puts "Today is #{my_today}"
            my_yesterday = my_today - 1
            updated_at_min = my_yesterday.strftime("%Y-%m-%d")
            puts "Yesterday was #{my_yesterday}, header_info = #{header_info}"
            num_updated_charges = background_count_partial_charges(my_yesterday, header_info)
            puts "We have #{num_updated_charges} customers who are new or have been updated since yesterday"
            
            
            background_load_partial_charges(sleep_recharge, num_updated_charges, header_info, uri, updated_at_min)

        else
            puts "Sorry can't understand what the option_value #{option_value} means"

        end

    end

    def background_count_partial_charges(my_yesterday, my_header)
        updated_at_min = my_yesterday.strftime("%Y-%m-%d")
        puts "Getting count of partial charges, since yesterday #{updated_at_min}"
         charge_count = HTTParty.get("https://api.rechargeapps.com/charges/count?updated_at_min=#{updated_at_min}", :headers => my_header)
         my_count = charge_count.parsed_response
         puts my_count
         
         num_charges = my_count['count']
         num_charges = num_charges.to_i
         return num_charges

    end

    def background_count_full_charges(my_header)
        puts "Getting charge count ... "
        charge_count = HTTParty.get("https://api.rechargeapps.com/charges/count", :headers => my_header)
        my_count = charge_count.parsed_response
        puts my_count.inspect
        num_charges = my_count['count']
        #puts num_charges
        num_charges = num_charges.to_i
        #puts num_charges
        return num_charges

    end

    def background_load_partial_charges(sleep_recharge, num_charges, header_info, uri, updated_at_min)
        puts "starting PARTIAL Download!"
        puts num_charges
        puts updated_at_min
        puts header_info
        puts uri
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        #puts "got here"
        

        my_insert_billing = "insert into charge_billing_address (address1, address2, city, company, country, first_name, last_name, phone, province, zip, charge_id) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement2', "#{my_insert_billing}")

        my_insert_client_details = "insert into charge_client_details (charge_id, browser_ip, user_agent) values ($1, $2, $3)"
        my_conn.prepare('statement3', "#{my_insert_client_details}")

        my_insert_fixed_line_items = "insert into charge_fixed_line_items (charge_id, grams, price, quantity, shopify_product_id, shopify_variant_id, sku, subscription_id, title, variant_title, vendor) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement4', "#{my_insert_fixed_line_items}")

        my_insert_variable_line_items = "insert into charge_variable_line_items (charge_id, name, value) values ($1, $2, $3)"
        my_conn.prepare('statement5', "#{my_insert_variable_line_items}")

        my_insert_charges_shipping_address = "insert into charges_shipping_address (charge_id, address1, address2, city, company, country, first_name, last_name, phone, province, zip) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement6', "#{my_insert_charges_shipping_address}")

        my_insert_charges_shipping_lines = "insert into charges_shipping_lines (charge_id, code, price, source, title, tax_lines, carrier_identifier, request_fulfillment_service_id) values ($1, $2, $3, $4, $5, $6, $7, $8)"
        my_conn.prepare('statement7', "#{my_insert_charges_shipping_lines}") 

        #puts "At here"
        start = Time.now
        page_size = 250
        num_pages = (num_charges/page_size.to_f).ceil
        1.upto(num_pages) do |page|
            charges = HTTParty.get("https://api.rechargeapps.com/charges?updated_at_min=#{updated_at_min}&limit=250&page=#{page}", :headers => header_info)
            my_charges = charges.parsed_response['charges']
            my_charges.each do |charge|
                #puts "-------------"
                #puts charge.inspect
                #puts "-------------"
                address_id = charge['address_id']
                raw_billing_address = charge['billing_address']
                billing_address = charge['billing_address'].to_json
                billing_address1 = raw_billing_address['address1']
                billing_address2 = raw_billing_address['address2']
                billing_address_city = raw_billing_address['city']
                billing_address_company = raw_billing_address['company']
                billing_address_country = raw_billing_address['country']
                billing_address_first_name = raw_billing_address['first_name']
                billing_address_last_name = raw_billing_address['last_name']
                billing_address_phone = raw_billing_address['phone']
                billing_address_province = raw_billing_address['province']
                billing_address_zip = raw_billing_address['zip']

                   

                client_details = charge['client_details'].to_json
                raw_client_details = charge['client_details']
                browser_ip = raw_client_details['browser_ip']
                user_agent = raw_client_details['user_agent']
               


                created_at = charge['created_at']
                customer_hash = charge['customer_hash']
                customer_id = charge['customer_id']
                discount_codes = charge['discount_codes'].to_json
                first_name = charge['first_name']
                charge_id = charge['id']
                #insert charge_billing_address sub-table
                #my_conn.exec_prepared('statement2', [billing_address1, billing_address2, billing_address_city, billing_address_company, billing_address_country, billing_address_first_name, billing_address_last_name, billing_address_phone, billing_address_province, billing_address_zip, charge_id ])

                #create charge_billing_address hash, and send it to method to determine
                #if insert or update

                charge_billing_address_hash = {"billing_address1" => billing_address1, "billing_address2" => billing_address2, "billing_address_city" => billing_address_city, "billing_address_company" => billing_address_company, "billing_address_country" => billing_address_country, "billing_address_first_name" => billing_address_first_name, "billing_address_last_name" => billing_address_last_name, "billing_address_phone" => billing_address_phone, "billing_address_province" => billing_address_province, "billing_address_zip" => billing_address_zip, "charge_id" => charge_id}

                insert_update_charge_billing_address(uri, charge_billing_address_hash)


                #my_conn.exec_prepared('statement3', [charge_id, browser_ip, user_agent])
                #create charge_client_details_hash and send to method for insert/update

                charge_client_details_hash = {"charge_id" => charge_id, "browser_ip" => browser_ip, "user_agent" => user_agent}

                if !browser_ip.nil?
                    insert_update_charge_client_details(uri, charge_client_details_hash)
                end

                #before updating/inserting variable line items delete everything in that table
                #with the id, and just insert only, its special case, can have many or one or
                #none variable line items -- name/value pair.
                special_delete_variable_line_items(uri, charge_id)

                last_name = charge['last_name']
                line_items = charge['line_items'].to_json
                raw_line_items = charge['line_items'][0]
                raw_line_items['properties'].each do |myitem|
                    #puts myitem
                    myname = myitem['name']
                    myvalue = myitem['value']
                    if myvalue == "" 
                        myvalue = nil
                    end
                    puts "#{charge_id}: #{myname} -> #{myvalue}"
                    
                    #create hash for charge_variable_line_items, send to method to determine
                    #if should update or insert

                    charge_variable_line_items = {"charge_id" => charge_id, "name" => myname, "value" => myvalue}
                    insert_update_charge_variable_line_items(uri, charge_variable_line_items)


                end
                
                grams = raw_line_items['grams']
                price = raw_line_items['price']
                if grams.nil?
                    grams = 0
                else
                    grams = grams.to_i
                end
                if price.nil?
                    price = 0.0
                else
                    price = price.to_f
                    price = price.round(2)
                end

                quantity = raw_line_items['quantity']
                shopify_product_id = raw_line_items['shopify_product_id']
                shopify_variant_id = raw_line_items['shopify_variant_id']
                sku = raw_line_items['sku']
                subscription_id = raw_line_items['subscription_id']
                title = raw_line_items['title']
                variant_title = raw_line_items['variant_title']
                vendor = raw_line_items['vendor']

                
                charge_fixed_line_items_hash = {"charge_id" => charge_id, "grams" => grams, "price" => price, "quantity" => quantity, "shopify_product_id" => shopify_product_id, "shopify_variant_id" => shopify_variant_id, "sku" => sku, "subscription_id" => subscription_id, "title" => title, "variant_title" => variant_title, "vendor" => vendor}

                insert_update_charge_fixed_line_items(uri, charge_fixed_line_items_hash)


                note = charge['note']
                note_attributes = charge['note_attributes'].to_json
                processed_at = charge['processed_at']
                scheduled_at = charge['scheduled_at']
                shipments_count = charge['shipments_count']
                shipping_address = charge['shipping_address'].to_json
                raw_shipping_address = charge['shipping_address']
                sa_address1 = raw_shipping_address['address1']
                sa_address2 = raw_shipping_address['address2']
                sa_city = raw_shipping_address['city']
                sa_company = raw_shipping_address['company']
                sa_country = raw_shipping_address['country']
                sa_first_name = raw_shipping_address['first_name']
                sa_last_name = raw_shipping_address['last_name']
                sa_phone = raw_shipping_address['phone']
                sa_province = raw_shipping_address['province']
                sa_zip = raw_shipping_address['zip']
                

                #construct hash and send to method to determine if insert or update
                charge_shipping_address_hash = {"charge_id" => charge_id, "address1" => sa_address1, "address2" => sa_address2, "city" => sa_city, "company" => sa_company, "country" => sa_country, "first_name" => sa_first_name, "last_name" => sa_last_name, "phone" => sa_phone, "province" => sa_province, "zip" => sa_zip}
                insert_update_shipping_address(uri, charge_shipping_address_hash)


                shipping_lines = charge['shipping_lines'][0]
                if !shipping_lines.nil?
                    sl_code = shipping_lines['code']
                    sl_price = shipping_lines['price'].to_f
                    sl_price = sl_price.round(2)
                    sl_source = shipping_lines['source']
                    sl_title = shipping_lines['title']
                    sl_tax_lines = shipping_lines['tax_lines'].to_json
                    sl_carrier_identifier = shipping_lines['carrier_identifier']
                    sl_request_fulfillment_service_id = shipping_lines['request_fulfillment_service_id']
                    

                    #construct hash and send to method to check to insert or update
                    shipping_lines_hash = {"charge_id" => charge_id, "code" => sl_code, "price" => sl_price, "source" => sl_source, "title" => sl_title, "tax_lines" => sl_tax_lines, "carrier_identifier" => sl_carrier_identifier, "request_fulfillment_service_id" => sl_request_fulfillment_service_id}

                    insert_update_shipping_lines(uri, shipping_lines_hash)


                end


                shopify_order_id = charge['shopify_order_id']
                status = charge['status']
                sub_total = charge['sub_total']
                sub_total_price = charge['sub_total_price']
                tags = charge['tags']
                tax_lines = charge['tax_lines']
                total_discounts = charge['total_discounts']
                total_line_items_price = charge['total_line_items_price']
                total_tax = charge['total_tax']
                total_weight = charge['total_weight']
                total_price = charge['total_price']
                updated_at = charge['updated_at']

                #construct hash, send it to method to either insert or update
                my_main_charge_hash = {"address_id" => address_id, "billing_address" => billing_address, "client_details" => client_details, "created_at" => created_at, "customer_hash" => customer_hash, "customer_id" => customer_id, "first_name" => first_name, "charge_id" => charge_id, "last_name" => last_name,"line_items" => line_items, "note" => note, "note_attributes" => note_attributes, "processed_at" => processed_at, "scheduled_at" => scheduled_at, "shipments_count" => shipments_count, "shipping_address" => shipping_address, "shopify_order_id" => shopify_order_id, "status" => status, "sub_total" => sub_total, "sub_total_price" => sub_total_price, "tags" => tags,"tax_lines" => tax_lines, "total_discounts" => total_discounts, "total_line_items_price" => total_line_items_price, "total_tax" => total_tax, "total_weight" => total_weight, "total_price" => total_price, "updated_at" => updated_at,  "discount_codes" => discount_codes }
                puts "Checking for insert or update main charge table"
                insert_update_main_charge(uri, my_main_charge_hash)

                end
            current = Time.now
            duration = (current - start).ceil
            puts "Running #{duration} seconds"
            puts "Done with page #{page}"
            puts "Sleeping #{sleep_recharge}"
            sleep sleep_recharge.to_i
        end
        puts "All done with downloading today's charges"
        puts "Ran #{(Time.now - start).ceil} seconds"

    end

    def insert_update_charge_billing_address(uri, charge_billing_address_hash)
        charge_id = charge_billing_address_hash['charge_id']
        billing_address1 = charge_billing_address_hash['billing_address1']
        billing_address2 = charge_billing_address_hash['billing_address2']
        billing_address_city = charge_billing_address_hash['billing_address_city']
        billing_address_company = charge_billing_address_hash['billing_address_company']
        billing_address_country = charge_billing_address_hash['billing_address_country']
        billing_address_first_name = charge_billing_address_hash['billing_address_first_name']
        billing_address_last_name = charge_billing_address_hash['billing_address_last_name']
        billing_address_phone = charge_billing_address_hash['billing_address_phone']
        billing_address_province = charge_billing_address_hash['billing_address_province']
        billing_address_zip = charge_billing_address_hash['billing_address_zip']
        
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)

        my_insert = "insert into charge_billing_address (charge_id, address1, address2, city, company, country, first_name, last_name, phone, province, zip) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement1', "#{my_insert}")
        my_temp_update = "update charge_billing_address set address1 = $1, address2 = $2, city = $3, company = $4, country = $5, first_name = $6, last_name = $7, phone = $8, province = $9, zip = $10 where charge_id = $11"
        my_conn.prepare('statement2', "#{my_temp_update}")
        temp_select = "select * from charge_billing_address where charge_id = \'#{charge_id}\'"
        temp_result = my_conn.exec(temp_select)
        if !temp_result.num_tuples.zero?
            puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            puts "Found existing charge_billing_address record"
            temp_result.each do |myrow|
                puts myrow.inspect
                charge_id = myrow['charge_id']
                puts "Charge ID #{charge_id}"
                indy_result = my_conn.exec_prepared('statement2', [billing_address1, billing_address2, billing_address_city, billing_address_company, billing_address_country, billing_address_first_name, billing_address_last_name, billing_address_phone, billing_address_province, billing_address_zip, charge_id])
                puts indy_result.inspect
                puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

            end
        else
            puts "*******************************"
            puts "Charge_billing_address Record does not exist, inserting"
            puts "*******************************"
            
            my_conn.exec_prepared('statement1', [ charge_id, billing_address1, billing_address2, billing_address_city, billing_address_company, billing_address_country, billing_address_first_name, billing_address_last_name, billing_address_phone, billing_address_province, billing_address_zip ])
            puts "inserted charge_client_details: #{charge_id} browser stuff"
        
        end
        my_conn.close

    end

    def insert_update_charge_client_details(uri, charge_client_details_hash)
        charge_id = charge_client_details_hash['charge_id']
        browser_ip = charge_client_details_hash['browser_ip']
        user_agent = charge_client_details_hash['user_agent']
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)

        my_insert = "insert into charge_client_details (charge_id, browser_ip, user_agent) values ($1, $2, $3)"
        my_conn.prepare('statement1', "#{my_insert}")
        my_temp_update = "update charge_client_details set browser_ip = $1, user_agent = $2 where charge_id = $3"
        my_conn.prepare('statement2', "#{my_temp_update}")
        temp_select = "select * from charge_client_details where charge_id = \'#{charge_id}\'"
        temp_result = my_conn.exec(temp_select)
        if !temp_result.num_tuples.zero?
            puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
            puts "Found existing charge_client_details record"
            temp_result.each do |myrow|
                puts myrow.inspect
                charge_id = myrow['charge_id']
                puts "Charge ID #{charge_id}"
                indy_result = my_conn.exec_prepared('statement2', [browser_ip, user_agent, charge_id])
                puts indy_result.inspect
                puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

            end
        else
            puts "*******************************"
            puts "Charge_Client_Details Record does not exist, inserting"
            puts "*******************************"
            
            my_conn.exec_prepared('statement1', [ charge_id, browser_ip, user_agent ])
            puts "inserted charge_client_details: #{charge_id} browser stuff"
        
        end
        my_conn.close

    end

    def special_delete_variable_line_items(uri, charge_id)
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_delete = "delete from charge_variable_line_items where charge_id = \'#{charge_id}\'"  
        my_conn.exec(my_delete) 

    end

    def insert_update_charge_variable_line_items(uri, charge_variable_line_items)
        #Special case, can have many or one or none charge_line_items, so we delete"
        #EVERTHING prior method call for charge_id
        #and just re-insert everything for that charge id.

        charge_id = charge_variable_line_items['charge_id']
        name = charge_variable_line_items['name']
        value = charge_variable_line_items['value']
        
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        if !name.nil? && !value.nil?
            my_insert = "insert into charge_variable_line_items (charge_id, name, value) values ($1, $2, $3)"
            my_conn.prepare('statement1', "#{my_insert}")
            my_insert_result = my_conn.exec_prepared('statement1', [ charge_id, name, value ])
            puts my_insert_result.inspect
            puts "inserted charge_variable_line_items: #{charge_id} and good to go here"
        end
           
        my_conn.close

    end

    def insert_update_charge_fixed_line_items(uri, charge_fixed_line_items_hash)
    
        charge_id = charge_fixed_line_items_hash['charge_id']
        grams = charge_fixed_line_items_hash['grams']
        price = charge_fixed_line_items_hash['price'].to_f
        price = price.round(2)
        quantity = charge_fixed_line_items_hash['quantity'].to_i
        shopify_product_id = charge_fixed_line_items_hash['shopify_product_id']
        shopify_variant_id = charge_fixed_line_items_hash['shopify_variant_id']
        sku = charge_fixed_line_items_hash['sku']
        subscription_id = charge_fixed_line_items_hash['subscription_id']
        title = charge_fixed_line_items_hash['title']
        variant_title = charge_fixed_line_items_hash['variant_title']
        vendor = charge_fixed_line_items_hash['vendor']

        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_insert = "insert into charge_fixed_line_items (charge_id, grams, price, quantity, shopify_product_id, shopify_variant_id, sku, subscription_id, title, variant_title, vendor) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement1', "#{my_insert}")
        my_temp_update = "update charge_fixed_line_items set grams = $1, price = $2,  quantity = $3, shopify_product_id = $4, shopify_variant_id = $5, sku = $6, subscription_id = $7, title = $8, variant_title = $9, vendor = $10 where charge_id = $11 "
        my_conn.prepare('statement2', "#{my_temp_update}")
        temp_select = "select * from charge_fixed_line_items where charge_id = \'#{charge_id}\'"
        temp_result = my_conn.exec(temp_select)
        if !temp_result.num_tuples.zero?
            puts "???????????????????????????????"
            puts "Found existing charge_fixed_line_items record"
            temp_result.each do |myrow|
                puts myrow.inspect
                charge_id = myrow['charge_id']
                puts "Charge ID #{charge_id}"
                indy_result = my_conn.exec_prepared('statement2', [grams, price, quantity, shopify_product_id, shopify_variant_id, sku, subscription_id, title, variant_title, vendor, charge_id])
                puts indy_result.inspect
                puts "???????????????????????????"

            end
        else
            puts "*******************************"
            puts "Charge Fixed Line Items Record does not exist, inserting"
            puts "*******************************"
            
            my_conn.exec_prepared('statement1', [ charge_id, grams, price, quantity, shopify_product_id, shopify_variant_id, sku, subscription_id, title, variant_title, vendor ])
            puts "inserted charge_fixed_line_items: #{charge_id} oh yeah"
        
        end
        my_conn.close
    end

    def insert_update_shipping_address(uri, charge_shipping_address_hash)
        
        charge_id = charge_shipping_address_hash['charge_id']
        address1 = charge_shipping_address_hash['address1']
        address2 = charge_shipping_address_hash['address2']
        city = charge_shipping_address_hash['city']
        company = charge_shipping_address_hash['company']
        country = charge_shipping_address_hash['country']
        first_name = charge_shipping_address_hash['first_name']
        last_name = charge_shipping_address_hash['last_name']
        phone = charge_shipping_address_hash['phone']
        province = charge_shipping_address_hash['province']
        zip = charge_shipping_address_hash['zip']

        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_insert = "insert into charges_shipping_address (charge_id, address1, address2, city, company, country, first_name, last_name, phone, province, zip) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement1', "#{my_insert}")
        my_temp_update = "update charges_shipping_address set address1 = $1, address2 = $2,  city = $3, company = $4, country = $5, first_name = $6, last_name = $7, phone = $8, province = $9, zip = $10 where charge_id = $11 "
        my_conn.prepare('statement2', "#{my_temp_update}")
        temp_select = "select * from charges_shipping_address where charge_id = \'#{charge_id}\'"
        temp_result = my_conn.exec(temp_select)
        if !temp_result.num_tuples.zero?
            puts "++++++++++++++++++++++++"
            puts "Found existing charge_shipping_address record"
            temp_result.each do |myrow|
                puts myrow.inspect
                charge_id = myrow['charge_id']
                puts "Charge ID #{charge_id}"
                indy_result = my_conn.exec_prepared('statement2', [address1, address2, city, company, country, first_name, last_name, phone, province, zip, charge_id])
                puts indy_result.inspect
                puts "++++++++++++++++++++++++++"

            end
        else
            puts "*******************************"
            puts "Shipping address Record does not exist, inserting"
            puts "*******************************"
            
            my_conn.exec_prepared('statement1', [ charge_id, address1, address2, city, company, country, first_name, last_name, phone, province, zip ])
            puts "inserted charge_shipping_address: #{charge_id} !!!!"
        
        end
        my_conn.close
    end


    def insert_update_shipping_lines(uri, shipping_lines_hash)
        
        charge_id = shipping_lines_hash['charge_id']
        code = shipping_lines_hash['code']
        price = shipping_lines_hash['price']
        my_source = shipping_lines_hash['source']
        title = shipping_lines_hash['title']
        tax_lines = shipping_lines_hash['tax_lines']
        carrier_identifier = shipping_lines_hash['carrier_identifier']
        request_fulfillment_service_id = shipping_lines_hash['request_fulfillment_service_id']

        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_insert = "insert into charges_shipping_lines (charge_id, code, price, source, title, tax_lines, carrier_identifier, request_fulfillment_service_id) values ($1, $2, $3, $4, $5, $6, $7, $8)"
        my_conn.prepare('statement1', "#{my_insert}")
        my_temp_update = "update charges_shipping_lines set code = $1, price = $2,  source = $3, title = $4, tax_lines = $5, carrier_identifier = $6, request_fulfillment_service_id = $7 where charge_id = $8 "
        my_conn.prepare('statement2', "#{my_temp_update}")
        temp_select = "select * from charges_shipping_lines where charge_id = \'#{charge_id}\'"
        temp_result = my_conn.exec(temp_select)
        if !temp_result.num_tuples.zero?
            puts "@@@@@@@@@@@@@@@@@@"
            puts "Found existing charge_shipping_lines record"
            temp_result.each do |myrow|
                puts myrow.inspect
                charge_id = myrow['charge_id']
                puts "Charge ID #{charge_id}"
                indy_result = my_conn.exec_prepared('statement2', [code, price, my_source, title, tax_lines, carrier_identifier, request_fulfillment_service_id, charge_id])
                puts indy_result.inspect
                puts "@@@@@@@@@@@@@@@@@@@@"

            end
        else
            puts "*******************************"
            puts "Record does not exist, inserting"
            puts "*******************************"
            
            my_conn.exec_prepared('statement1', [ charge_id, code, price, my_source, title, tax_lines, carrier_identifier, request_fulfillment_service_id ])
            puts "inserted charge_shipping_lines: #{charge_id}"
        
        end
        my_conn.close
        
    end

    def insert_update_main_charge(uri, my_main_charge_hash)
        #puts uri.inspect
        #puts my_main_charge_hash
        address_id = my_main_charge_hash['address_id']
        billing_address = my_main_charge_hash['billing_address'].to_json
        client_details = my_main_charge_hash['client_details'].to_json
        created_at = my_main_charge_hash['created_at']
        customer_hash = my_main_charge_hash['customer_hash']
        customer_id = my_main_charge_hash['customer_id']
        first_name = my_main_charge_hash['first_name']
        last_name = my_main_charge_hash['last_name']
        line_items = my_main_charge_hash['line_items'].to_json
        note = my_main_charge_hash['note']
        note_attributes = my_main_charge_hash['note_attributes'].to_json
        processed_at = my_main_charge_hash['processed_at']
        scheduled_at = my_main_charge_hash['scheduled_at']
        shipments_count = my_main_charge_hash['shipments_count']
        shipping_address = my_main_charge_hash['shipping_address'].to_json
        shopify_order_id = my_main_charge_hash['shopify_order_id']
        status = my_main_charge_hash['status']
        sub_total = my_main_charge_hash['subtotal']
        sub_total_price = my_main_charge_hash['sub_total_price']
        tags = my_main_charge_hash['tags']
        tax_lines = my_main_charge_hash['tax_lines']
        total_discounts = my_main_charge_hash['total_discounts']
        total_line_items_price = my_main_charge_hash['total_line_items_price']
        total_tax = my_main_charge_hash['total_tax']
        total_weight = my_main_charge_hash['total_weight']
        total_price = my_main_charge_hash['total_price']
        updated_at = my_main_charge_hash['updated_at']
        discount_codes = my_main_charge_hash['discount_codes'].to_json
        charge_id = my_main_charge_hash['charge_id']


        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        my_insert = "insert into charges (address_id, billing_address, client_details, created_at, customer_hash, customer_id, first_name, charge_id, last_name, line_items, note, note_attributes, processed_at, scheduled_at, shipments_count, shipping_address, shopify_order_id, status, sub_total, sub_total_price, tags, tax_lines, total_discounts, total_line_items_price, total_tax, total_weight, total_price, updated_at, discount_codes) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29)"
        my_conn.prepare('statement1', "#{my_insert}")
        my_temp_update = "update charges set address_id = $1, billing_address = $2,  client_details = $3, customer_hash = $4, customer_id = $5, first_name = $6, last_name = $7, line_items = $8, note = $9, note_attributes = $10, processed_at = $11, scheduled_at = $12, shipments_count = $13, shipping_address = $14, shopify_order_id = $15, status = $16, sub_total = $17, sub_total_price = $18, tags = $19, tax_lines = $20, total_discounts = $21, total_line_items_price = $22, total_tax = $23, total_weight = $24, total_price = $25, updated_at = $26, discount_codes = $27  where charge_id = $28 "
        my_conn.prepare('statement2', "#{my_temp_update}")

        #determine if charge already exists in DB, if so update rather than insert
        temp_select = "select * from charges where charge_id = \'#{charge_id}\'"
        temp_result = my_conn.exec(temp_select)
        if !temp_result.num_tuples.zero?
            puts "&&&&&&&&&&&&&&&&&"
            puts "Found existing record"
            temp_result.each do |myrow|
                #puts myrow.inspect
                charge_id = myrow['charge_id']
                puts "Charge ID #{charge_id}"
                indy_result = my_conn.exec_prepared('statement2', [address_id, billing_address,client_details, customer_hash, customer_id, first_name, last_name, line_items, note, note_attributes, processed_at, scheduled_at, shipments_count, shipping_address, shopify_order_id, status, sub_total, sub_total_price, tags, tax_lines, total_discounts, total_line_items_price, total_tax, total_weight, total_price, updated_at, discount_codes, charge_id])
                puts indy_result.inspect
                puts "&&&&&&&&&&&&&&&&&&"
            end
        else
            puts "*******************************"
            puts "Record does not exist, inserting"
            puts "*******************************"
            
            my_conn.exec_prepared('statement1', [ address_id, billing_address, client_details, created_at, customer_hash, customer_id, first_name, charge_id, last_name, line_items, note, note_attributes, processed_at, scheduled_at, shipments_count, shipping_address, shopify_order_id, status, sub_total, sub_total_price, tags, tax_lines, total_discounts, total_line_items_price, total_tax, total_weight, total_price, updated_at,  discount_codes ])
            puts "inserted charge #{charge_id}"
        end
        my_conn.close

    end

    def background_load_full_charges(sleep_recharge, num_charges, header_info, uri)
        puts "starting FULL download"
        
        
        puts header_info
        puts uri
        myuri = URI.parse(uri)
        my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
        puts "got here"
        my_insert = "insert into charges (address_id, billing_address, client_details, created_at, customer_hash, customer_id, first_name, charge_id, last_name, line_items, note, note_attributes, processed_at, scheduled_at, shipments_count, shipping_address, shopify_order_id, status, sub_total, sub_total_price, tags, tax_lines, total_discounts, total_line_items_price, total_tax, total_weight, total_price, updated_at, discount_codes) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29)"
        my_conn.prepare('statement1', "#{my_insert}")

        my_insert_billing = "insert into charge_billing_address (address1, address2, city, company, country, first_name, last_name, phone, province, zip, charge_id) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement2', "#{my_insert_billing}")

        my_insert_client_details = "insert into charge_client_details (charge_id, browser_ip, user_agent) values ($1, $2, $3)"
        my_conn.prepare('statement3', "#{my_insert_client_details}")

        my_insert_fixed_line_items = "insert into charge_fixed_line_items (charge_id, grams, price, quantity, shopify_product_id, shopify_variant_id, sku, subscription_id, title, variant_title, vendor) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement4', "#{my_insert_fixed_line_items}")

        my_insert_variable_line_items = "insert into charge_variable_line_items (charge_id, name, value) values ($1, $2, $3)"
        my_conn.prepare('statement5', "#{my_insert_variable_line_items}")

        my_insert_charges_shipping_address = "insert into charges_shipping_address (charge_id, address1, address2, city, company, country, first_name, last_name, phone, province, zip) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)"
        my_conn.prepare('statement6', "#{my_insert_charges_shipping_address}")

        my_insert_charges_shipping_lines = "insert into charges_shipping_lines (charge_id, code, price, source, title, tax_lines, carrier_identifier, request_fulfillment_service_id) values ($1, $2, $3, $4, $5, $6, $7, $8)"
        my_conn.prepare('statement7', "#{my_insert_charges_shipping_lines}") 

        start = Time.now
        page_size = 250
        num_pages = (num_charges/page_size.to_f).ceil
        1.upto(num_pages) do |page|
            charges = HTTParty.get("https://api.rechargeapps.com/charges?limit=250&page=#{page}", :headers => header_info)
            my_charges = charges.parsed_response['charges']
            my_charges.each do |charge|
                puts "-------------"
                puts charge.inspect
                puts "-------------"
                address_id = charge['address_id']
                raw_billing_address = charge['billing_address']
                billing_address = charge['billing_address'].to_json
                billing_address1 = raw_billing_address['address1']
                billing_address2 = raw_billing_address['address2']
                billing_address_city = raw_billing_address['city']
                billing_address_company = raw_billing_address['company']
                billing_address_country = raw_billing_address['country']
                billing_address_first_name = raw_billing_address['first_name']
                billing_address_last_name = raw_billing_address['last_name']
                billing_address_phone = raw_billing_address['phone']
                billing_address_province = raw_billing_address['province']
                billing_address_zip = raw_billing_address['zip']

                   

                client_details = charge['client_details'].to_json
                raw_client_details = charge['client_details']
                browser_ip = raw_client_details['browser_ip']
                user_agent = raw_client_details['user_agent']
               


                created_at = charge['created_at']
                customer_hash = charge['customer_hash']
                customer_id = charge['customer_id']
                discount_codes = charge['discount_codes'].to_json
                first_name = charge['first_name']
                charge_id = charge['id']
                #insert charge_billing_address sub-table
                my_conn.exec_prepared('statement2', [billing_address1, billing_address2, billing_address_city, billing_address_company, billing_address_country, billing_address_first_name, billing_address_last_name, billing_address_phone, billing_address_province, billing_address_zip, charge_id ])

                if !browser_ip.nil?
                    my_conn.exec_prepared('statement3', [charge_id, browser_ip, user_agent])
                end

                last_name = charge['last_name']
                line_items = charge['line_items'].to_json
                raw_line_items = charge['line_items'][0]
                raw_line_items['properties'].each do |myitem|
                    puts myitem
                    myname = myitem['name']
                    myvalue = myitem['value']
                    if myvalue == "" 
                        myvalue = nil
                    end
                    puts "#{charge_id}: #{myname} -> #{myvalue}"
                    if !myvalue.nil?
                        my_conn.exec_prepared('statement5', [charge_id, myname, myvalue])
                    end
                end
                
                grams = raw_line_items['grams']
                price = raw_line_items['price']
                if grams.nil?
                    grams = 0
                else
                    grams = grams.to_i
                end
                if price.nil?
                    price = 0.0
                else
                    price = price.to_f
                    price = price.round(2)
                end

                quantity = raw_line_items['quantity']
                shopify_product_id = raw_line_items['shopify_product_id']
                shopify_variant_id = raw_line_items['shopify_variant_id']
                sku = raw_line_items['sku']
                subscription_id = raw_line_items['subscription_id']
                title = raw_line_items['title']
                variant_title = raw_line_items['variant_title']
                vendor = raw_line_items['vendor']

                my_conn.exec_prepared('statement4', [charge_id, grams, price, quantity, shopify_product_id, shopify_variant_id, sku, subscription_id, title, variant_title, vendor])


                note = charge['note']
                note_attributes = charge['note_attributes'].to_json
                processed_at = charge['processed_at']
                scheduled_at = charge['scheduled_at']
                shipments_count = charge['shipments_count']
                shipping_address = charge['shipping_address'].to_json
                raw_shipping_address = charge['shipping_address']
                sa_address1 = raw_shipping_address['address1']
                sa_address2 = raw_shipping_address['address2']
                sa_city = raw_shipping_address['city']
                sa_company = raw_shipping_address['company']
                sa_country = raw_shipping_address['country']
                sa_first_name = raw_shipping_address['first_name']
                sa_last_name = raw_shipping_address['last_name']
                sa_phone = raw_shipping_address['phone']
                sa_province = raw_shipping_address['province']
                sa_zip = raw_shipping_address['zip']
                my_conn.exec_prepared('statement6', [charge_id, sa_address1, sa_address2, sa_city, sa_company, sa_country, sa_first_name, sa_last_name, sa_phone, sa_province, sa_zip])

                shipping_lines = charge['shipping_lines'][0]
                if !shipping_lines.nil?
                    sl_code = shipping_lines['code']
                    sl_price = shipping_lines['price'].to_f
                    sl_price = sl_price.round(2)
                    sl_source = shipping_lines['source']
                    sl_title = shipping_lines['title']
                    sl_tax_lines = shipping_lines['tax_lines'].to_json
                    sl_carrier_identifier = shipping_lines['carrier_identifier']
                    sl_request_fulfillment_service_id = shipping_lines['request_fulfillment_service_id']
                    my_conn.exec_prepared('statement7', [charge_id, sl_code, sl_price, sl_source, sl_title, sl_tax_lines, sl_carrier_identifier, sl_request_fulfillment_service_id])
                end


                shopify_order_id = charge['shopify_order_id']
                status = charge['status']
                sub_total = charge['sub_total']
                sub_total_price = charge['sub_total_price']
                tags = charge['tags']
                tax_lines = charge['tax_lines']
                total_discounts = charge['total_discounts']
                total_line_items_price = charge['total_line_items_price']
                total_tax = charge['total_tax']
                total_weight = charge['total_weight']
                total_price = charge['total_price']
                updated_at = charge['updated_at']

                my_conn.exec_prepared('statement1', [ address_id, billing_address, client_details, created_at, customer_hash, customer_id, first_name, charge_id, last_name, line_items, note, note_attributes, processed_at, scheduled_at, shipments_count, shipping_address, shopify_order_id, status, sub_total, sub_total_price, tags, tax_lines, total_discounts, total_line_items_price, total_tax, total_weight, total_price, updated_at,  discount_codes ])
                end
            current = Time.now
            duration = (current - start).ceil
            puts "Running #{duration} seconds"
            puts "Done with page #{page}"
            puts "Sleeping #{sleep_recharge}"
            sleep sleep_recharge.to_i
        end
        puts "All done with charges"
        puts "Ran #{(Time.now - start).ceil} seconds"
    end

end