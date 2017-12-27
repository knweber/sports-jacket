#!/bin/sh
ROOT=`git rev-parse --show-cdup`

get() {
  curl -s -H "X-Recharge-Access-Token: $RECHARGE_ACCESS_TOKEN" -X GET $1
}

sub_id=`get https://api.rechargeapps.com/subscriptions | jq '.subscriptions | last | .id'`
echo sub_id $sub_id
order_id=`get https://api.rechargeapps.com/orders | jq '.orders | last | .id'`
echo order_id $order_id
charge_id=`get https://api.rechargeapps.com/charges | jq '.charges | last | .id'`
echo charge_id $charge_id
customer_id=`get https://api.rechargeapps.com/customers | jq '.customers | last | .id'`
echo customer_id $customer_id

get "https://api.rechargeapps.com/subscriptions/$sub_id" | jq . | tee $ROOT/docs/subscription_example.json
get "https://api.rechargeapps.com/orders/$order_id" | jq . | tee $ROOT/docs/order_example.json
get "https://api.rechargeapps.com/charges/$charge_id" | jq . | tee $ROOT/docs/charge_example.json
get "https://api.rechargeapps.com/customers/$customer_id" | jq . | tee $ROOT/docs/customer_example.json
