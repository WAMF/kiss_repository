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

  # Create data directory
  mkdir -p "$project_dir/pb_data"
  cd "$project_dir" || return 1

  # Start PocketBase
  pocketbase serve --http=127.0.0.1:8090 --dir=pb_data >"$log_file" 2>&1 &
  echo $!  # Return PID
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