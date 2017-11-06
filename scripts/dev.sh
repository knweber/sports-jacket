#!/bin/bash
docker build -t production_pull . &&
docker run --rm -it --env-file .env -p 9292:9292 production_pull bash
