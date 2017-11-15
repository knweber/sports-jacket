# Ellie Production Backend

This application contains the background processing for ellie. Processing is
handled by Resque. This container starts `resque-web` and 1 worker for each
queue when invoked.

## Current production tasks

* `charge_pull[ yesterday | full_pull ]`
* `customer_pull[ yesterday | full_pull ]`
* `order_pull[ yesterday | full_pull ]`
* `subscription_pull[ yesterday | full_pull ]`

## Building the Image
For development:
`docker build -t pull .`

## Running the Tests
`rake test`

## Running the Container
```bash
./docker_run.sh <development | production>
```

## Queueing jobs from the container

`docker exec <container> rake -f /app/Rakefile <job>`

## Web API Endpoints

### `GET /subscriptions`

Returns a list of subscriptions. Filters currently match the
[Recharge API](https://developer.rechargepayments.com/#list-subscriptions).

### `PUT /subscriptions/:subscription_id`

Updates a subscription. Only the fields provided in the body will be updated.
The rest are left alone.

Returns the resulting full subscription data. [Example
output.](docs/subscription_example.json)

### `GET /subscriptions/:subscription_id`

Returns a single subscription.
[Example output.](docs/subscription_example.json)


### `GET /subscriptions/:subscription_id/sizes`

Returns the sizes of the given subscription ID.

Example output:
```json
{
  "tops": "XL",
  "leggings": "M",
  "sports-bra": "XS",
  "sports-jacket": "S",
}
```

### `PUT /subscriptions/:subscription_id/sizes`

Updates the sizes of the given subscription ID. Takes a json object keyed by the

product type with the value of the new size.Returns the complete set of
sizes from the subscription.

Valid keys:
* "tops"
* "leggings"
* "sports-bra"
* "sports-jackets"

Valid values:
* "XS"
* "S"
* "M"
* "L"
* "XL"

Example:

```javascript
# before update
{
  "tops": "XL",
  "leggings": "M",
  "sports-bra": "XS",
  "sports-jacket": "S",
}

# updates with the body of:
{ "tops": "S" }

# resulting output
{
  "tops": "S",
  "leggings": "M",
  "sports-bra": "XS",
  "sports-jacket": "S",
}
```

### `POST /subscription/:subscription_id/skip`

Skips the subscription forward 1 month if the subscription is able to be
skipped. The update to Recharge is queued for background processing. The
subscription object returned is an optimistic representation of the final state
of the subscription. `skipped` indicates whether the subscription was
successfully skipped. `subscription` is a subscription object with the
`next_scheduled_charge_date` optimistically updated.

Example Request:
```json
{
  "action": "skip_month",
  "shopify_customer_id": "123456789",
  "reason": "other"
}
```

Returns:
```json
{
  "skipped": true,
  "subscription": {
    ...
    "next_scheduled_charge_date": "2017-06-18",
    ...
  }
}
```

