#!/bin/bash
cd /app

function finish {
  jobs -p | xargs kill
}

trap finish EXIT

#QUEUE=pull_charge rake resque:work &
#QUEUE=pull_order rake resque:work &
#QUEUE=pull_subscription rake resque:work &
#QUEUE=pull_customer rake resque:work &

#resque-web -LF -p 5678 --redis $REDIS_URL &
rackup
#bash
