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
        #alt_3pack_prod_id = ENV['ALT_ELLIE_3PACK_PRODUCT_ID']
        #alt_monthly_prod_id = ENV['ALT_MONTHLY_PRODUCT_ID']
        #monthly_box_prod_id = ENV['MONTHLY_PRODUCT_ID']
        #ellie_3pack_prod_id = ENV['ELLIE_3PACK_PRODUCT_ID']
        #logger.info "alt_monthly_prod_id = #{alt_monthly_prod_id}"

        #subs_update = "insert into subscriptions_updated (subscription_id, customer_id, updated_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id) select subscription_id, customer_id, updated_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id from subscriptions where status = 'ACTIVE' and next_charge_scheduled_at > \'#{my_end_month_str}\' and (shopify_product_id = \'#{alt_monthly_prod_id}\' or shopify_product_id = \'#{alt_3pack_prod_id}\' or shopify_product_id = \'#{monthly_box_prod_id}\' or shopify_product_id = \'#{ellie_3pack_prod_id}\')"
        bad_prod_id1 = "10016265938"
        bad_prod_id2 = "10870682450"
        bad_prod_id3 = "44383469586"
        bad_prod_id4 = "820544081"
        

        subs_update = "insert into subscriptions_updated (subscription_id, customer_id, updated_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id) select subscription_id, customer_id, updated_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id from subscriptions where status = 'ACTIVE' and updated_at > '2017-11-30' and (shopify_product_id = \'#{bad_prod_id1}\' or shopify_product_id = \'#{bad_prod_id2}\' or shopify_product_id = \'#{bad_prod_id3}\' or shopify_product_id = \'#{bad_prod_id4}\')"



        conn.exec(subs_update)
        conn.close
        logger.info "Done setting up subscriptions_updated table!"

    end

    def new_product_properties(my_product_id)
        stuff_to_return = {}
        alt_3pack_prod_id = ENV['ALT_ELLIE_3PACK_PRODUCT_ID']
        alt_monthly_prod_id = ENV['ALT_MONTHLY_PRODUCT_ID']
        monthly_box_prod_id = ENV['MONTHLY_PRODUCT_ID']
        ellie_3pack_prod_id = ENV['ELLIE_3PACK_PRODUCT_ID']
        
        new_ellie_3pack_prod = CurrentProduct.find_by prod_id_key: 'ellie_3pack_prod_id'
        new_ellie_3pack_id = new_ellie_3pack_prod.prod_id_value
        new_alt3pack_prod = CurrentProduct.find_by prod_id_key: 'alt_3pack_prod_id'
        new_alt3pack_prod_id = new_alt3pack_prod.prod_id_value
        new_monthly_prod = CurrentProduct.find_by prod_id_key: 'monthly_box_prod_id'
        new_monthly_prod_id = new_monthly_prod.prod_id_value
        new_alt_monthly_prod = CurrentProduct.find_by prod_id_key: 'alt_monthly_prod_id'
        new_alt_monthly_prod_id = new_alt_monthly_prod.prod_id_value
        monthly_product = UpdateProduct.find_by(product_title: 'Power Moves - 5 Item' )
        ellie_3pack = UpdateProduct.find_by(product_title: 'Power Moves - 3 Item' )


        #puts new_ellie_3pack_id

        case my_product_id
        when new_alt_monthly_prod_id 
        #customer has monthly box, return Alternate Monthly Box  
        stuff_to_return = {"sku" => monthly_product.sku, "product_title" => monthly_product.product_title, "shopify_product_id" => monthly_product.shopify_product_id, "shopify_variant_id" => monthly_product.shopify_variant_id}
        when new_alt3pack_prod_id
        #Customer has Ellie 3- Pack, return Alternate Ellie 3- Pack
        stuff_to_return = {"sku" => ellie_3pack.sku, "product_title" => ellie_3pack.product_title, "shopify_product_id" => ellie_3pack.shopify_product_id, "shopify_variant_id" => ellie_3pack.shopify_variant_id}
        when new_monthly_prod_id
        stuff_to_return = {"sku" => monthly_product.sku, "product_title" => monthly_product.product_title, "shopify_product_id" => monthly_product.shopify_product_id, "shopify_variant_id" => monthly_product.shopify_variant_id}  
        when new_ellie_3pack_id
        stuff_to_return = {"sku" => ellie_3pack.sku, "product_title" => ellie_3pack.product_title, "shopify_product_id" => ellie_3pack.shopify_product_id, "shopify_variant_id" => ellie_3pack.shopify_variant_id}      
        else
        #Give them the Alt 3-Pack
        stuff_to_return = {"sku" => ellie_3pack.sku, "product_title" => ellie_3pack.product_title, "shopify_product_id" => ellie_3pack.shopify_product_id, "shopify_variant_id" => ellie_3pack.shopify_variant_id}

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


            my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{my_sub_id}", :headers => recharge_change_header, :body => body, :timeout => 80)
            puts my_update_sub.inspect
            Resque.logger.info my_update_sub.inspect
            if my_update_sub.code == 200
                sub.updated = true
                time_updated = DateTime.now
                time_updated_str = time_updated.strftime("%Y-%m-%d %H:%M:%S")
                sub.processed_at = time_updated_str
                sub.save


            else
                Resque.logger.warn "WARNING -- COULD NOT UPDATE subscription #{my_sub_id}"
            end
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