require_relative 'resque_helper'

class SubscriptionSkip
  extend ResqueHelper
  @queue = 'skip_product'
  def self.perform(params)
    update_success = false
    Resque.logger = Logger.new("#{Dir.getwd}/logs/skip_resque.log")
    puts "Got this: #{params.inspect}"
    #POST /subscriptions/<subscription_id>/set_next_charge_date
    subscription_id = params['subscription_id']
    shopify_customer_id = params['shopify_customer_id']
    my_reason = params['reason']
    my_sub = Subscription.find(subscription_id)
    my_customer = Customer.find_by(shopify_customer_id: shopify_customer_id)
    my_customer_id = my_customer.customer_id

    begin
      my_now = Date.today
      puts my_sub.inspect
      temp_next_charge = my_sub.next_charge_scheduled_at.to_s
      puts temp_next_charge
      my_next_charge = my_sub.try(:next_charge_scheduled_at).try('+', 1.month)
      puts "Now next charge date = #{my_next_charge.inspect}"
      next_charge_str = my_next_charge.strftime("%Y-%m-%d")
      puts "We will change the next_charge_scheduled_at to: #{next_charge_str}"
      recharge_change_header = params['recharge_change_header']
      body = {"date" => next_charge_str}.to_json
      puts "Pushing new charge_date to ReCharge: #{body}"
      my_update_sub = HTTParty.post("https://api.rechargeapps.com/subscriptions/#{subscription_id}/set_next_charge_date", :headers => recharge_change_header, :body => body, :timeout => 80)
      update_success = my_update_sub.success?
      puts my_update_sub.inspect
      Resque.logger.info(my_update_sub.inspect)
    rescue Exception => e
      Resque.logger.error(e.inspect)
    end

    update_success = true
    puts "****** Hooray We have no errors **********"
    Resque.logger.info("****** Hooray We have no errors **********")
    Resque.enqueue(SendEmailToCustomer, subscription_id)
    puts "We are adding to skip_reasons table"
    skip_reason = SkipReason.create(customer_id:  my_customer_id, shopify_customer_id:  shopify_customer_id, subscription_id:  subscription_id, reason:  my_reason, skipped_to:  next_charge_str, skip_status:  update_success, created_at:  my_now )
    puts skip_reason.inspect

    puts "We were not able to update the subscription" unless update_success
    Resque.enqueue(SendEmailToCS, subscription_id) unless update_success
    Resque.logger.info("We were not able to update the subscription") unless update_success

  end
end
