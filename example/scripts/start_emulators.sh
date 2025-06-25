#!/bin/bash

# Central Emulator Manager
# Dynamically discovers and manages emulators from the emulators/ directory

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EMULATORS_DIR="$SCRIPT_DIR/emulators"

declare -a RUNNING_PIDS=() RUNNING_SERVICES=() AVAILABLE_EMULATORS=()

trap cleanup SIGINT SIGTERM

cleanup() {
  echo -e "\n${YELLOW}🛑 Stopping emulators...${NC}"
  
  # Kill tracked processes
  for pid in "${RUNNING_PIDS[@]}"; do kill "$pid" 2>/dev/null; done
  
  # Stop all running services
  for service in "${RUNNING_SERVICES[@]}"; do
    local emulator_file="$EMULATORS_DIR/${service,,}.sh"
    if [ -f "$emulator_file" ]; then
      source "$emulator_file"
      stop
    fi
  done
  
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

# Discover available emulators
discover_emulators() {
  AVAILABLE_EMULATORS=()
  for emulator_file in "$EMULATORS_DIR"/*.sh; do
    [ -f "$emulator_file" ] || continue
    local name=$(basename "$emulator_file" .sh)
    AVAILABLE_EMULATORS+=("$name")
  done
}

# Load emulator and check if installed
load_emulator() {
  local name="$1"
  local emulator_file="$EMULATORS_DIR/${name}.sh"
  
  if [ ! -f "$emulator_file" ]; then
    return 1
  fi
  
  source "$emulator_file"
  return 0
}

# Check and warn about missing emulators
check_emulators() {
  for emulator in "${AVAILABLE_EMULATORS[@]}"; do
    if load_emulator "$emulator"; then
      if ! check_installed; then
        print warn "$EMULATOR_NAME not installed - skipping (install with: brew install ${emulator,,} or similar)"
      fi
    fi
  done
}

# Start an emulator
start_emulator() {
  local name="$1"
  local emulator_file="$EMULATORS_DIR/${name}.sh"
  
  if ! load_emulator "$name"; then
    print error "Emulator $name not found"
    return 1
  fi
  
  if ! check_installed; then
    print warn "$EMULATOR_NAME not installed - skipping"
    return 1
  fi
  
  print info "🚀 Starting $EMULATOR_NAME..."
  
  # Check if already running by checking primary port
  local primary_port="${EMULATOR_PORTS[0]}"
  if lsof -i :"$primary_port" >/dev/null 2>&1; then
    print success "$EMULATOR_NAME already running ($EMULATOR_URL)"
    RUNNING_SERVICES+=("$EMULATOR_NAME")
    return 0
  fi
  
  # Start the emulator
  local log_file="$SCRIPT_DIR/${name}.log"
  local pid
  pid=$(start "$PROJECT_DIR" "$log_file")
  local start_result=$?
  
  if [ $start_result -eq 0 ] && [ -n "$pid" ]; then
    RUNNING_PIDS+=("$pid")
    
    # Wait and verify startup
    sleep 3
    if kill -0 "$pid" 2>/dev/null || lsof -i :"$primary_port" >/dev/null 2>&1; then
      RUNNING_SERVICES+=("$EMULATOR_NAME")
      print success "$EMULATOR_NAME started ($EMULATOR_URL)"
      
      # Show special info for PocketBase
      if [[ "$name" == "pocketbase" ]]; then
        echo -e "  ${CYAN}👥 Test user:${NC} testuser@example.com / testuser123"
        echo -e "  ${CYAN}👤 Admin:${NC}     test@test.com / testpassword123"
        echo -e "  ${CYAN}🔗 Admin UI:${NC}  http://127.0.0.1:8090/_/"
      fi
      
      # Show logs if available
      if [ -f "$log_file" ]; then
        tail -f "$log_file" &
        RUNNING_PIDS+=($!)
      fi
      return 0
    else
      print error "$EMULATOR_NAME failed to start"
      return 1
    fi
  else
    print error "$EMULATOR_NAME failed to start"
    return 1
  fi
}

# Start all available emulators
start_all_emulators() {
  echo -e "\n${CYAN}🚀 Starting all available emulators...${NC}"
  
  for emulator in "${AVAILABLE_EMULATORS[@]}"; do
    start_emulator "$emulator"
  done
}

# Main function
main() {
  print header
  
  # Discover available emulators
  discover_emulators
  
  if [ ${#AVAILABLE_EMULATORS[@]} -eq 0 ]; then
    print error "No emulators found in $EMULATORS_DIR"
    exit 1
  fi
  
  # Check emulators and show warnings
  check_emulators
  
  # Start all emulators
  start_all_emulators
  
  # Wait for emulators
  if [ ${#RUNNING_SERVICES[@]} -gt 0 ]; then
    echo -e "\n${GREEN}🎉 Running: ${RUNNING_SERVICES[*]}${NC}"
    if [ ${#RUNNING_PIDS[@]} -gt 0 ]; then
      echo -e "${YELLOW}Press Ctrl+C to stop...${NC}"
      wait
    else
      echo -e "${YELLOW}All emulators were already running. Press Ctrl+C to exit.${NC}"
      while true; do sleep 1; done
    fi
  else
    print warn "No emulators started"
  fi
}

main "$@" 