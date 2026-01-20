@echo off

echo "Stopping backend container..."
docker-compose -f docker-compose.yml down --timeout 60

echo "Creating backend network..."
docker network create backend_network

echo "Building backend container ..."
@REM docker-compose build --no-cache
docker-compose -f docker-compose.yml build

echo "Starting backend container..."
docker-compose -f docker-compose.yml up --remove-orphans --force-recreate -d

echo "Backend container started successfully!"
