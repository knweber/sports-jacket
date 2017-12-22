# Docker Administration and Development Guide

## Build the application
```shell
docker-compose build
```

## Launch the application
```shell
docker-compose up -d
```

## Shutdown the application
```shell
docker-compose down
```

## Run a one-off command in a temporary container (recommended)
```shell
docker-compose run --rm --no-deps ellie_worker $command $arg1 $arg2 ...
```

__Explanation:__
* `run` tells docker to launch a new container
* `--rm` remove the container after the command exits
* `--no-deps` tells docker-compose not to launch any dependencies of the given
  container
* `ellie_worker` is the name of the service to use as the base for running the
  command in. This can be replaced with any of the service names defined in
  `docker-compose.yml`
* All arguments passed after the container name will be treated as if they were
  a program run for the command line inside the project root of the container.
  You cannot reference any files that are not part of the service image.

> NOTE: Docker containers are at their core a collection of settings used for
> running a process. There must be at least 1 process running in a container for
> it to be active.

## Run a one-off command in an existing container (not recommended)
```shell
docker-compose exec $service_name $command $arg1 $arg2 ...
```

## Scale a service
`ellie_admin`, `ellie_web`, and `ellie_worker` are the services currently
capable of being scaled. This scaling only lasts for this run of the containers.
To make the scaling changes permanent add `scale: N` to the appropriate service
in `docker-compose.yml`
```shell
docker-compose scale ellie_worker=5
```

## Check logs
Docker automatically logs any output to stdout for any of its containers.
Checking log files not output to an external volume is significantly more
difficult.

Output all logs since launch. If `service_name` is included only the logs from
containers running that service will be output.
```shell
docker-compose logs [service_name]
```

Follow all logs like `tail -f`. If `service_name` is provided only logs from
containers running that service will be returned.
```shell
docker-compose logs -f [service_name]
```

## Develop remotely
From your local development machine:
```shell
cd $project_directory

watchexec 'rsync -rv --delete ./ $server_url:$project_directory/'
```

On the server:
```shell
cd $project_directory

watchexec -r 'docker-compose build && docker-compose up -d && docker-compose
logs -f'
```

Develop locally with your favorite editor. `rsync` will keep a perfect mirror on
the server. When any changes are made the server will automatically rebuild and
relaunch the application. This is a particularly nice workflow when working on a
flaky connection since losing connection to the server does not affect the
local project files and `rsync` will just update the project on the server the
next time it has a connection.


