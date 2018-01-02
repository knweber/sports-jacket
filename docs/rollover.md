# Rollover Guide

This guide provides step by step instructions for rolling over the ellie.com
manually.

To run commands on the server from an account without `rbenv` or `rvm` installed
you can run them using an on demand docker container by prefixing any commands
here with the following:

```shell
docker-compose run --rm --no-deps ellie_worker $given_command
```

1. Make sure the database is fully migrated. `rake db:migrate`

1. Add the new `ProductTag`s with the appropriate `theme_id`, `active_start`,
   and `active_end`.

1. (optional) Create a product map for updating the appropriate subscription
products. This map should be stored in the `Config` table with a key following
the format of `rollover_subscription_products_2018-12-01`. The value should be a
hash keyed by the `shopify_product_id` to change with a value od a hash
containing the new subscription values (likely the `shopify_product_id` and
`shopify_product_variant`). Eg:
```ruby
Config['rollover_subscription_products'] = {
  '123456789' => {
    shopify_product_id: 214354657,
    shopify_variant_id: 987654321,
  }
}
```

1. Update subscriptions to the new products for this month.
```shell
ruby -r ./scripts/pry_context.rb -e 'Rollover.subscription_products
<my_product_map>'`
```

1. Launch the new theme either manually or through Shopify's Launchpad.
