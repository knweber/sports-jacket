#resque_helper
require 'dotenv'
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


end