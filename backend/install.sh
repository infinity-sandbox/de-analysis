#!/bin/bash

echo "Stopping backend container..."
docker-compose -f docker-compose.yml down --timeout 30

docker network create backend_network

echo "Building backend container..."
docker-compose -f docker-compose.yml build
# docker-compose -f docker-compose build --no-cache

echo "Starting backend container..."
docker-compose -f docker-compose.yml up --remove-orphans --force-recreate -d

echo "Backend container started successfully!"
