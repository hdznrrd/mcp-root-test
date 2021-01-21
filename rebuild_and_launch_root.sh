#!/bin/sh

set -e

cd MCP-Root
git pull
./mvnw clean install
cp target/root-ca-list-0.0.1-SNAPSHOT.war docker
cd docker
docker stop mcp || echo
docker rm mcp || echo
docker build -t mcp .
docker run -p 8080:8080 --name mcp mcp 
