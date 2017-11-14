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



    stuff_to_return = {}
    case myprod_id
    when monthly_product_id
      #customer has monthly box, return Alternate Monthly Box
      stuff_to_return = {"sku" => alt_monthly_sku, 'product_title' => alt_monthly_title, 'shopify_product_id' => alt_monthly_product_id, "shopify_variant_id" => alt_monthly_variant_id}
    when ellie_3pack_product_id
      #Customer has Ellie 3- Pack, return Alternate Ellie 3- Pack
      stuff_to_return = {"sku" => alt_ellie3pack_sku, 'product_title' => alt_ellie3pack_title, 'alt_product_id' => "10870682450", "alt_variant_id" => "46480736274"}
    else
      #Give them the Alt 3-Pack
      stuff_to_return = {"sku" => alt_ellie3pack_sku, "product_title" => alt_ellie3pack_title, "shopify_product_id" => alt_montly_product_id, "shopify_variant_id" => alt_monthly_variant_id}

    end
    return stuff_to_return

  end


end

class SubscriptionSwitch
  extend ResqueHelper
  @queue = 'switch_product'
  def self.perform(params)
    #puts params.inspect
    Resque.logger = Logger.new("#{Dir.getwd}/logs/resque.log")

    #{"action"=>"switch_product", "subscription_id"=>"8672750", "product_id"=>"8204555081"}
    subscription_id = params['subscription_id']
    product_id = params['product_id']
    puts "We are working on subscription #{subscription_id}"
    Resque.logger.info("We are working on subscription #{subscription_id}")

    temp_hash = provide_alt_products(product_id)
    puts temp_hash
    Resque.logger.info("new product info for subscription #{subscription_id} is #{temp_hash}")

    recharge_change_header = params['recharge_change_header']
    puts recharge_change_header
    body = temp_hash.to_json

    puts body
    #puts "Got here hoser"



    my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{subscription_id}", :headers => recharge_change_header, :body => body, :timeout => 80)
    puts my_update_sub.inspect
    Resque.logger.info(my_update_sub.inspect)


    update_success = false
    if my_update_sub.code == 200
      update_success = true
      puts "****** Hooray We have no errors **********"
      Resque.logger.info("****** Hooray We have no errors **********")
    else
      puts "We were not able to update the subscription"
      Resque.logger.info("We were not able to update the subscription")
    end

  end
end
