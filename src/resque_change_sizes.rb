require 'resque'
require_relative 'recharge_api'

class ChangeSizes

  extend ResqueHelper
  @queue = 'change_sizes'
  def self.perform(subscription_id, new_sizes)
    sub = Subscription.find subscription_id
    sub.sizes = new_sizes
    body = {properties: sub.raw_line_item_properties}
    res = RechargeAPI.put("/subscriptions/#{sub.subscription_id}", body: body.to_json)
    puts "recharge_response: #{res.response}"
    new_props = res.parsed_response['subscription']['properties']
    puts "new sub props: #{new_props}"
    Subscription.find(subscription_id).update(raw_line_item_properties: new_props)
  end
end
