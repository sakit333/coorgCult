#!/bin/bash

docker run -d \
  --name postgres-db \
  -e POSTGRES_USER=root \
  -e POSTGRES_PASSWORD=1234 \
  -e POSTGRES_DB=coorgcult \
  -p 5432:5432 \
  postgres

# To Access PostgreSQL Container
#  docker exec -it postgres-db psql -U root -d coorgcult