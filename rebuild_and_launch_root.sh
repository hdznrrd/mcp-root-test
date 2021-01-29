#!/bin/sh

set -e

cd MCP-Root
git pull
./mvnw clean install
cp target/root-ca-list-0.0.1-SNAPSHOT.war docker
cd docker
docker-compose stop || echo
docker-compose rm || echo
docker-compose build
docker-compose up
