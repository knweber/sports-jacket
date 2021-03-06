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
Manually:
`docker build -t <your_image_name[:<your_version>]> .`

## Running the Container
For development:
`./scripts/dev.sh`
Environment is sourced from `.env.development`

For production:
`./scripts/prod.sh`
Environment is sourced from `.env.production`

## Running the Tests
`rake test`

Note another useful method for testing is to load the environment into `pry`.
Use `pry -r ./scripts/pry_context.rb` for easy loading of the entire project.
The `test_customer` variable is available in this scope for fast business logic
tests.

## Queueing jobs from the container

`docker exec <container> rake -f /app/Rakefile <job>`

## Web API Endpoints

### `GET /subscriptions`

Returns a list of subscriptions. Filters currently match the
[Recharge API](https://developer.rechargepayments.com/#list-subscriptions).

### `PUT /subscription/:subscription_id`

Updates a subscription. Only the fields provided in the body will be updated.
The rest are left alone.

Returns the resulting full subscription data. [Example
output.](docs/subscription_example.json)

### `GET /subscription/:subscription_id`

Returns a single subscription.
[Example output.](docs/subscription_example.json)


### `GET /subscription/:subscription_id/sizes`

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

# updated with the body of:
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
    "next_scheduled_charge_at": "2017-06-18",
    ...
  }
}
```

### `GET /skippable_subscriptions?shopify_id=12345678`

Returns a list of active subscriptions what have a `product_id` that is able to be
skipped or have an alternate product chosen for it.

Example return:
```json
[
    {
        "next_charge_scheduled_at": "2017-11-27", 
        "shopify_product_id": "10016265938", 
        "shopify_product_title": "Ellie 3- Pack", 
        "skippable": false, 
        "subscription_id": "7671575",
        "can_choose_alt_product": true,
    }, 
    ...
]
```
