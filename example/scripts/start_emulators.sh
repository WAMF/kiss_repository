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

# Install missing emulators
install_missing() {
  for emulator in "${AVAILABLE_EMULATORS[@]}"; do
    if load_emulator "$emulator"; then
      if ! check_installed; then
        print warn "$EMULATOR_NAME not installed, attempting installation..."
        if install; then
          print success "$EMULATOR_NAME installed successfully"
        else
          print error "Failed to install $EMULATOR_NAME"
        fi
      fi
    fi
  done
}

# Show emulator status
show_status() {
  echo -e "\n${CYAN}📋 Available Emulators:${NC}"
  local index=1
  
  for emulator in "${AVAILABLE_EMULATORS[@]}"; do
    if load_emulator "$emulator"; then
      local status="❌ Not installed"
      if check_installed; then
        status="${GREEN}✅ Installed${NC}"
      fi
      echo -e "$index) $EMULATOR_NAME - $status"
      ((index++))
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
    print error "$EMULATOR_NAME not installed"
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

# Get user selection and start emulators
run_selection() {
  echo -e "\n${CYAN}🎯 Select emulators to start (e.g., '1 3' or Enter for all):${NC}"
  read -r selection
  
  # Default to all if empty
  if [[ -z "$selection" ]]; then
    selection=$(seq 1 ${#AVAILABLE_EMULATORS[@]})
  fi
  
  # Start selected emulators
  for num in $selection; do
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#AVAILABLE_EMULATORS[@]} ]; then
      local emulator_name="${AVAILABLE_EMULATORS[$((num-1))]}"
      start_emulator "$emulator_name"
    else
      print warn "Invalid selection: $num"
    fi
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
  
  # Install missing emulators
  install_missing
  
  # Show status
  show_status
  
  # Get selection and start emulators
  run_selection
  
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