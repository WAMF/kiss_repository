#!/bin/bash

# Firebase Emulator Implementation
EMULATOR_NAME="Firebase"
EMULATOR_PORTS=(4000 9099 8080)
EMULATOR_URL="http://localhost:4000"

start() {
  local project_dir="$1"
  local log_file="$2"
  
  # Check if already running
  if lsof -i :4000 >/dev/null 2>&1; then
    return 0  # Already running
  fi

  # Setup firebase.json
  cd "$project_dir" || return 1
  [ ! -f firebase.json ] && cat > firebase.json <<EOF
{
  "projects": {"default": "demo-kiss-example"},
  "emulators": {
    "auth": {"port": 9099},
    "firestore": {"port": 8080},
    "ui": {"enabled": true, "port": 4000}
  }
}
EOF

  # Start Firebase emulators
  firebase emulators:start --only auth,firestore --project demo-kiss-example >"$log_file" 2>&1 &
  echo $!  # Return PID
}

stop() {
  pkill -f "firebase.*emulators:start" 2>/dev/null || true
}

check_installed() {
  command -v firebase >/dev/null 2>&1
}

install() {
  if command -v npm >/dev/null 2>&1; then
    npm install -g firebase-tools
    return $?
  else
    echo "npm not found. Install Node.js: brew install node"
    return 1
  fi
}
