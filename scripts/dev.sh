#!/bin/bash
NAME=ellie_2

function finish {
  echo "Stopping jobs..."
  jobs -p | xargs kill
  echo "Stoping containsers..."
  docker rm -f ${NAME}_web ${NAME}_worker
  echo "Goodbye!"
}

trap finish EXIT

docker build -t ${NAME}_web -f Dockerfile.web . &&
docker build -t ${NAME}_worker -f Dockerfile.worker . &&
docker run -d \
  --name ${NAME}_web \
  --env-file .env.docker \
  -p 9292:9292 \
  ${NAME}_web
docker run -d \
  --name ${NAME}_worker \
  --env-file .env.docker \
  -e QUEUE=* \
  ${NAME}_worker

docker logs -f ${NAME}_web &
docker logs -f ${NAME}_worker &

read -n1 -r -p "Press a key to continue..." key
