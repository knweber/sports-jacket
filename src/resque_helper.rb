#resque_helper
require 'dotenv'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'httparty'
require_relative 'logging'
require_relative 'models/model'

Dotenv.load

module ResqueHelper
    def provide_alt_products(myprod_id)
        #puts "Got to the helper"
        
        #set up product ids, variant ids, skus, etc. from env variable.
        
        monthly_product_id = ENV['MONTHLY_PRODUCT_ID']
        ellie_3pack_product_id = ENV['ELLIE_3PACK_PRODUCT_ID']
        
        alt_monthly_title = ENV['ALT_MONTHLY_TITLE']
        alt_monthly_sku = ENV['ALT_MONTHLY_SKU']
        alt_monthly_product_id = ENV['ALT_MONTHLY_PRODUCT_ID']
        alt_monthly_variant_id = ENV['ALT_MONTHLY_VARIANT_ID']

        alt_ellie3pack_title = ENV['ALT_ELLIE_3PACK_TITLE']
        alt_ellie3pack_sku = ENV['ALT_ELLIE_3PACK_SKU']
        alt_montly_product_id = ENV['ALT_MONTHLY_PRODUCT_ID']
        alt_monthly_variant_id = ENV['ALT_MONTHLY_VARIANT_ID']
        alt_ellie3pack_variant_id = ENV['ALT_ELLIE_3PACK_VARIANT_ID'] 
        alt_ellie_3pack_product_id = ENV['ALT_ELLIE_3PACK_PRODUCT_ID']


        
        stuff_to_return = {}
        case myprod_id
        when monthly_product_id 
            #customer has monthly box, return Alternate Monthly Box  
            stuff_to_return = {"sku" => alt_monthly_sku, "product_title" => alt_monthly_title, "shopify_product_id" => alt_monthly_product_id, "shopify_variant_id" => alt_monthly_variant_id}
        when ellie_3pack_product_id
            #Customer has Ellie 3- Pack, return Alternate Ellie 3- Pack
            stuff_to_return = {"sku" => alt_ellie3pack_sku, "product_title" => alt_ellie3pack_title, "shopify_product_id" => alt_ellie_3pack_product_id, "shopify_variant_id" => alt_ellie3pack_variant_id}
        else
            #Give them the Alt 3-Pack
            stuff_to_return = {"sku" => alt_ellie3pack_sku, "product_title" => alt_ellie3pack_title, "shopify_product_id" => alt_ellie_3pack_product_id, "shopify_variant_id" => alt_ellie3pack_variant_id}

        end
        return stuff_to_return

    end


    def setup_subscription_update(params)
        uri = URI.parse(ENV['DATABASE_URL'])
        conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
        logger.info "Got the params #{params.inspect}"

        logger.warn "Deleting information in the subscriptions_updated table"
        subs_delete = "delete from subscriptions_updated"
        subs_reset = "ALTER SEQUENCE subscriptions_updated_id_seq RESTART WITH 1"
        conn.exec(subs_delete)
        conn.exec(subs_reset)
        my_now = Date.today
        my_end_month = my_now.end_of_month
        my_end_month_str = my_end_month.strftime("%Y-%m-%d 23:59:59")
        puts "my_end_month_str = #{my_end_month_str}"
        logger.info "my_end_month_str = #{my_end_month_str}"
        alt_3pack_prod_id = ENV['ALT_ELLIE_3PACK_PRODUCT_ID']
        alt_monthly_prod_id = ENV['ALT_MONTHLY_PRODUCT_ID']
        logger.info "alt_monthly_prod_id = #{alt_monthly_prod_id}"

        subs_update = "insert into subscriptions_updated (subscription_id, customer_id, updated_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id) select subscription_id, customer_id, updated_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id from subscriptions where status = 'ACTIVE' and next_charge_scheduled_at > \'#{my_end_month_str}\' and (shopify_product_id = \'#{alt_monthly_prod_id}\' or shopify_product_id = \'#{alt_3pack_prod_id}\')"
        conn.exec(subs_update)
        conn.close
        logger.info "Done setting up subscriptions_updated table!"

    end

    def new_product_properties(my_product_id)
        stuff_to_return = {}
        alt_3pack_prod_id = ENV['ALT_ELLIE_3PACK_PRODUCT_ID']
        alt_monthly_prod_id = ENV['ALT_MONTHLY_PRODUCT_ID']

        case my_product_id
        when alt_monthly_prod_id 
        #customer has monthly box, return Alternate Monthly Box  
        stuff_to_return = {"sku" => "111", "product_title" => "222", "shopify_product_id" => "333", "shopify_variant_id" => "444"}
        when alt_3pack_prod_id
        #Customer has Ellie 3- Pack, return Alternate Ellie 3- Pack
        stuff_to_return = {"sku" => "555", "product_title" => "666", "shopify_product_id" => "777", "shopify_variant_id" => "888"}
        else
        #Give them the Alt 3-Pack
        stuff_to_return = {"sku" => "555", "product_title" => "666", "shopify_product_id" => "777", "shopify_variant_id" => "888"}

        end


        return stuff_to_return
    end

    

    def update_subscription_product(params)
        Resque.logger = Logger.new("#{Dir.getwd}/logs/update_subs_resque.log")
        Resque.logger.info "For updating subscriptions Got params #{params.inspect}"
        my_now = Time.now
        recharge_change_header = params['recharge_change_header']
        Resque.logger.info recharge_change_header
        my_subs = SubscriptionsUpdated.where("updated = ?", false)
        my_subs.each do |sub|
            Resque.logger.info sub.inspect
            #update stuff here
            my_sub_id = sub.subscription_id
            my_product_id = sub.shopify_product_id
            my_body = new_product_properties(my_product_id)
            Resque.logger.info "New Product Properties for subscription_id #{my_sub_id} ==> #{my_body}"
            body = my_body.to_json


            #my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{subscription_id}", :headers => recharge_change_header, :body => body, :timeout => 80)
            #puts my_update_sub.inspect
            Resque.logger.info "Sleeping 6 seconds"
            sleep 6
            my_current = Time.now
            duration = (my_current - my_now).ceil
            Resque.logger.info "Been running #{duration} seconds"
            if duration > 480
                Resque.logger.info "Been running more than 8 minutes must exit"
                exit
                
            end
            
        end
        Resque.logger.info "All Done, all subscriptions updated!" 

    end

    


end