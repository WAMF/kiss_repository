#!/bin/bash

# DynamoDB Emulator Implementation
EMULATOR_NAME="DynamoDB"
EMULATOR_PORTS=(8000)
EMULATOR_URL="http://localhost:8000"

start() {
  local project_dir="$1"
  local log_file="$2"
  
  # Check if already running
  if docker ps --format '{{.Names}}' | grep -q "dynamodb-local"; then
    return 0  # Already running
  fi

  # Stop and remove existing container if it exists
  docker stop dynamodb-local 2>/dev/null || true
  docker rm dynamodb-local 2>/dev/null || true

  # Create data directory
  mkdir -p "$project_dir/dynamodb_data"

  # Start DynamoDB Local
  docker run -d --name dynamodb-local -p 8000:8000 \
    -v "$project_dir/dynamodb_data:/home/dynamodblocal/data" \
    amazon/dynamodb-local:2.5.2 \
    -jar DynamoDBLocal.jar -sharedDb -dbPath ./data -disableTelemetry >"$log_file" 2>&1

  return $?
}

stop() {
  docker stop dynamodb-local >/dev/null 2>&1 || true
  docker rm dynamodb-local >/dev/null 2>&1 || true
}

check_installed() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

install() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not found. Install: brew install --cask docker"
    return 1
  elif ! docker info >/dev/null 2>&1; then
    echo "Docker not running. Please start Docker Desktop"
    return 1
  else
    return 0
  fi
} 