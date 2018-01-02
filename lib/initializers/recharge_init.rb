require_relative '../async'
Recharge.api_key = ENV['RECHARGE_ACCESS_TOKEN']
Recharge::Address.include Async
Recharge::Customer.include Async
Recharge::Charge.include Async
Recharge::Order.include Async
Recharge::Subscription.include Async
Recharge::Webhook.include Async
