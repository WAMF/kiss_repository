#!/bin/bash

# PocketBase Emulator Implementation
EMULATOR_NAME="PocketBase"
EMULATOR_PORTS=(8090)
EMULATOR_URL="http://127.0.0.1:8090"

start() {
  local project_dir="$1"
  local log_file="$2"
  
  # Check if already running
  if lsof -i :8090 >/dev/null 2>&1; then
    return 0  # Already running
  fi

  # Clean and create data directory
  rm -rf "$project_dir/pb_data" "$project_dir/pb_migrations"
  mkdir -p "$project_dir/pb_data"
  cd "$project_dir" || return 1

  # Start PocketBase
  pocketbase serve --http=127.0.0.1:8090 --dir=pb_data >"$log_file" 2>&1 &
  local pb_pid=$!
  
  # Wait for PocketBase to initialize
  sleep 3
  
  # Verify PocketBase is responding
  for i in {1..10}; do
    if curl -s "http://127.0.0.1:8090/api/health" > /dev/null 2>&1; then
      break
    fi
    if [ $i -eq 10 ]; then
      return 1  # Failed to start
    fi
    sleep 1
  done
  
  # Setup schema in background
  setup_schema "$project_dir" &
  
  # Give schema setup a moment to start
  sleep 1
  
  echo $pb_pid  # Return main PID
}

setup_schema() {
  local project_dir="$1"
  cd "$project_dir" || return 1
  
  # Create superuser
  pocketbase superuser upsert test@test.com testpassword123 --dir="pb_data" > /dev/null 2>&1
  sleep 2
  
  # Get admin token
  local admin_token=$(curl -s -X POST http://127.0.0.1:8090/api/collections/_superusers/auth-with-password \
    -H "Content-Type: application/json" \
    -d '{"identity": "test@test.com", "password": "testpassword123"}' | \
    grep -o '"token":"[^"]*' | cut -d'"' -f4)
  
  [ -z "$admin_token" ] && return 1
  
  # Create products collection
  curl -s -X POST http://127.0.0.1:8090/api/collections \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $admin_token" \
    -d '{
      "name": "products",
      "type": "base",
      "fields": [
        {"name": "name", "type": "text", "required": true},
        {"name": "price", "type": "number", "required": true},
        {"name": "description", "type": "text", "required": false},
        {"name": "created", "type": "autodate", "onCreate": true, "onUpdate": false},
        {"name": "updated", "type": "autodate", "onCreate": true, "onUpdate": true}
      ],
      "listRule": "@request.auth.id != \"\"",
      "viewRule": "@request.auth.id != \"\"",
      "createRule": "@request.auth.id != \"\"",
      "updateRule": "@request.auth.id != \"\"",
      "deleteRule": "@request.auth.id != \"\""
    }' > /dev/null
  
  # Create test user
  curl -s -X POST http://127.0.0.1:8090/api/collections/users/records \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $admin_token" \
    -d '{
      "email": "testuser@example.com",
      "password": "testuser123",
      "passwordConfirm": "testuser123",
      "name": "Test User"
    }' > /dev/null
}

stop() {
  pkill -f "pocketbase.*serve" 2>/dev/null || true
}

check_installed() {
  command -v pocketbase >/dev/null 2>&1
}

install() {
  if command -v brew >/dev/null 2>&1; then
    brew install pocketbase
    return $?
  else
    echo "Homebrew not found. Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 1
  fi
}
