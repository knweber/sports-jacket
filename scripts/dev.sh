#!/bin/bash
NAME=ellie_2
docker build -t ellie_2 . &&
docker run --rm -it --env-file .env.docker -p 9292:9292 $NAME bash
