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

## Running the Container
```bash
./docker_run.sh <development | production>
```

## Queueing jobs from the container

`docker exec <container> rake -f /app/Rakefile <job>`

## Web API Endpoints

### `GET /subscriptions`

### `PUT /subscriptions`

### `GET /subscriptions/<subscription_id>`

### `GET /subscriptions/:subscription_id/sizes`

### `PUT /subscriptions/:subscription_id/sizes`
