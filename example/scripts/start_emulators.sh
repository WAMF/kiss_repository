#!/bin/bash

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -a RUNNING_PIDS=() RUNNING_SERVICES=()

trap cleanup SIGINT SIGTERM

cleanup() {
  echo -e "\n${YELLOW}🛑 Stopping emulators...${NC}"
  for pid in "${RUNNING_PIDS[@]}"; do kill "$pid" 2>/dev/null; done
  docker stop dynamodb-local >/dev/null 2>&1 && docker rm dynamodb-local >/dev/null 2>&1
  echo -e "${GREEN}✅ All emulators stopped${NC}"; exit 0
}

print() {
  case "$1" in
    success) echo -e "${GREEN}✅ $2${NC}" ;;
    error) echo -e "${RED}❌ $2${NC}" ;;
    warn) echo -e "${YELLOW}⚠️  $2${NC}" ;;
    info) echo -e "${BLUE}ℹ️  $2${NC}" ;;
    header) echo -e "${PURPLE}🚀 KISS Emulator Manager${NC}\n${CYAN}=========================${NC}" ;;
  esac
}

check_port() { lsof -i :"$1" >/dev/null 2>&1; }

check_cmd() { command -v "$1" >/dev/null 2>&1; }

start_firebase() {
  print info "🔥 Starting Firebase..."
  check_port 4000 && { print success "Firebase already running"; RUNNING_SERVICES+=("Firebase"); return; }

  cd "$PROJECT_DIR"/.. || cd "$PROJECT_DIR"
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

  firebase emulators:start --only auth,firestore --project demo-kiss-example >"$PROJECT_DIR/firebase.log" 2>&1 &
  local pid=$!
  RUNNING_PIDS+=($pid) 
  RUNNING_SERVICES+=("Firebase")
  
  # Wait a bit for startup, then check if it's running
  sleep 3
  if kill -0 "$pid" 2>/dev/null; then
    print success "Firebase started (http://localhost:4000)"
    # Show logs in background
    tail -f "$PROJECT_DIR/firebase.log" &
    RUNNING_PIDS+=($!)
  else
    print error "Firebase failed to start"
    return 1
  fi
}

start_dynamodb() {
  print info "🗄️  Starting DynamoDB..."
  docker ps --format '{{.Names}}' | grep -q "dynamodb-local" && { print success "DynamoDB already running"; RUNNING_SERVICES+=("DynamoDB"); return; }
  
  # Stop and remove existing container if it exists
  docker stop dynamodb-local 2>/dev/null || true
  docker rm dynamodb-local 2>/dev/null || true
  
  mkdir -p "$PROJECT_DIR/../dynamodb_data"
  docker run -d --name dynamodb-local -p 8000:8000 \
    -v "$PROJECT_DIR/../dynamodb_data:/home/dynamodblocal/data" \
    amazon/dynamodb-local:2.5.2 \
    -jar DynamoDBLocal.jar -sharedDb -dbPath ./data -disableTelemetry
    
  if [ $? -eq 0 ]; then
    RUNNING_SERVICES+=("DynamoDB")
    print success "DynamoDB started (http://localhost:8000)"
  else
    print error "DynamoDB failed to start"
    return 1
  fi
}

start_pocketbase() {
  print info "📱 Starting PocketBase..."
  check_port 8090 && { print success "PocketBase already running"; RUNNING_SERVICES+=("PocketBase"); return; }
  mkdir -p "$PROJECT_DIR/../pb_data" && cd "$PROJECT_DIR/.."
  pocketbase serve --http=127.0.0.1:8090 --dir=pb_data >"$PROJECT_DIR/scripts/pocketbase.log" 2>&1 &
  local pid=$!
  RUNNING_PIDS+=($pid) 
  RUNNING_SERVICES+=("PocketBase")
  
  # Wait a bit for startup, then check if it's running
  sleep 2
  if kill -0 "$pid" 2>/dev/null; then
    print success "PocketBase started (http://127.0.0.1:8090)"
    # Show logs in background
    tail -f "$PROJECT_DIR/scripts/pocketbase.log" &
    RUNNING_PIDS+=($!)
  else
    print error "PocketBase failed to start"
    return 1
  fi
}

install_missing() {
  ! check_cmd firebase && print warn "Firebase CLI missing" && check_cmd npm && npm install -g firebase-tools
  ! check_cmd docker && print error "Docker missing or not running"
  ! check_cmd pocketbase && check_cmd brew && brew install pocketbase
}

show_status() {
  echo -e "\n${CYAN}📋 Emulator Status:${NC}"
  echo -e "1) Firebase     - $(check_cmd firebase && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")"
  echo -e "2) DynamoDB     - $(check_cmd docker && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")"
  echo -e "3) PocketBase   - $(check_cmd pocketbase && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")"
}

run_selection() {
  echo -e "\n${CYAN}🎯 Select emulators to start (1 2 3 or Enter for all):${NC}"
  read -r selection

  [[ -z "$selection" ]] && selection="1 2 3"

  for num in $selection; do
    case $num in
      1) check_cmd firebase && start_firebase || print error "Missing Firebase CLI" ;;
      2) check_cmd docker && start_dynamodb || print error "Docker unavailable" ;;
      3) check_cmd pocketbase && start_pocketbase || print error "Missing PocketBase" ;;
      *) print warn "Invalid selection: $num" ;;
    esac
  done
}

main() {
  print header
  install_missing
  show_status
  run_selection

  if [ ${#RUNNING_SERVICES[@]} -gt 0 ]; then
    echo -e "\n${GREEN}🎉 Running: ${RUNNING_SERVICES[*]}${NC}"
    if [ ${#RUNNING_PIDS[@]} -gt 0 ]; then
      echo -e "${YELLOW}Press Ctrl+C to stop...${NC}"
      wait
    else
      echo -e "${YELLOW}All emulators were already running. Press Ctrl+C to exit monitoring.${NC}"
      # Keep script alive to show we're monitoring
      while true; do sleep 1; done
    fi
  fi
}

main
